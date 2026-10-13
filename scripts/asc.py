#!/usr/bin/env python3
"""
App Store Connect, with the API key, before the 30-minute build starts:

  python3 scripts/asc.py prepare   registers the app's bundle ID if it isn't yet, then checks that the
                                   app exists in App Store Connect. Exits 2 with what to do when it
                                   doesn't (Apple only lets an app be created on the website).

Needs ASC_KEY_ID, ASC_ISSUER_ID and ASC_KEY_PATH (the .p8 file). Standard library and the openssl
command only, so it runs on a fresh GitHub Mac with nothing installed.
"""
import base64
import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.request

API = "https://api.appstoreconnect.apple.com/v1"
BUNDLE_ID = os.environ.get("BUNDLE_ID", "com.mojo.sdahymnal")
APP_NAME = os.environ.get("APP_NAME", "SDA Hymnal")


def b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode()


def der_to_raw(der: bytes) -> bytes:
    """openssl signs ECDSA as DER (r, s); a JWT wants the two 32-byte numbers side by side."""
    def read_int(buf, i):
        assert buf[i] == 0x02
        n = buf[i + 1]
        val = buf[i + 2 : i + 2 + n]
        return val.lstrip(b"\x00").rjust(32, b"\x00"), i + 2 + n

    i = 2 if der[1] < 0x80 else 3
    r, i = read_int(der, i)
    s, _ = read_int(der, i)
    return r + s


def token() -> str:
    key_id = os.environ["ASC_KEY_ID"]
    issuer = os.environ["ASC_ISSUER_ID"]
    key_path = os.environ["ASC_KEY_PATH"]
    now = int(time.time())
    head = b64url(json.dumps({"alg": "ES256", "kid": key_id, "typ": "JWT"}).encode())
    body = b64url(json.dumps({"iss": issuer, "iat": now, "exp": now + 900, "aud": "appstoreconnect-v1"}).encode())
    signing_input = f"{head}.{body}".encode()
    der = subprocess.run(["openssl", "dgst", "-sha256", "-sign", key_path], input=signing_input, capture_output=True, check=True).stdout
    return f"{head}.{body}.{b64url(der_to_raw(der))}"


def call(method: str, path: str, payload=None):
    req = urllib.request.Request(API + path, method=method, data=json.dumps(payload).encode() if payload else None)
    req.add_header("Authorization", "Bearer " + token())
    req.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            return r.status, json.loads(r.read() or b"{}")
    except urllib.error.HTTPError as e:
        try:
            return e.code, json.loads(e.read() or b"{}")
        except Exception:
            return e.code, {}


def errors(body) -> str:
    return "; ".join(f"{e.get('title')}: {e.get('detail')}" for e in body.get("errors", [])) or json.dumps(body)[:400]


def prepare() -> int:
    # 1. The bundle ID, registered under the team if it isn't already.
    code, body = call("GET", f"/bundleIds?filter[identifier]={BUNDLE_ID}&limit=5")
    if code == 401 or code == 403:
        print(f"App Store Connect turned the API key away ({code}): {errors(body)}")
        return 1
    found = [b for b in body.get("data", []) if b.get("attributes", {}).get("identifier") == BUNDLE_ID]
    if found:
        print(f"Bundle ID {BUNDLE_ID}: already registered")
    else:
        code, body = call("POST", "/bundleIds", {"data": {"type": "bundleIds", "attributes": {"identifier": BUNDLE_ID, "name": APP_NAME, "platform": "IOS"}}})
        if code in (200, 201):
            print(f"Bundle ID {BUNDLE_ID}: registered now")
        else:
            print(f"Bundle ID {BUNDLE_ID}: could not register ({code}): {errors(body)}")
            return 1

    # 2. The app itself. Apple's API can't create one, so this only checks.
    code, body = call("GET", f"/apps?filter[bundleId]={BUNDLE_ID}&limit=5")
    apps = [a for a in body.get("data", []) if a.get("attributes", {}).get("bundleId") == BUNDLE_ID]
    if apps:
        a = apps[0]["attributes"]
        print(f"App Store Connect app: {a.get('name')} (Apple ID {apps[0]['id']})")
        return 0
    print(
        "\nThe app isn't in App Store Connect yet, so there is nowhere to upload the build.\n"
        "Create it once at https://appstoreconnect.apple.com/apps → + → New App:\n"
        f"  Platform: iOS   Name: {APP_NAME} (any free name)   Language: English (U.K.)\n"
        f"  Bundle ID: {BUNDLE_ID}   SKU: sdahymnal   User access: Full access\n"
        "Then run this workflow again (Actions → TestFlight → Run workflow)."
    )
    return 2


if __name__ == "__main__":
    if len(sys.argv) < 2 or sys.argv[1] != "prepare":
        print(__doc__)
        sys.exit(64)
    sys.exit(prepare())
