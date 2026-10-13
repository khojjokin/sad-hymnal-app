# Shipping to TestFlight

Every push to `main` builds the app on a GitHub Mac with Xcode 26 and uploads it to TestFlight. It uses the same Apple team (QRMLKZR9B8) and App Store Connect API key (PD6DWK7T4C) as the Community app. You can also start a build from **Actions → TestFlight → Run workflow**.

Signing is automatic: Xcode creates or reuses the distribution certificate and profile with the API key, so there are no certificate files to manage.

## One-time setup (about 5 minutes)

### 1. Add the API key as a secret

Find the key file `AuthKey_PD6DWK7T4C.p8`, the one you downloaded from App Store Connect for the Community app. In Terminal on your Mac:

```bash
base64 -i ~/Downloads/AuthKey_PD6DWK7T4C.p8 | pbcopy
```

(Change the path to wherever the file is. If it isn't in Downloads, try `~/.appstoreconnect/private_keys/`.)

On GitHub, open **sad-hymnal-app → Settings → Secrets and variables → Actions → New repository secret**:

- Name: `ASC_KEY_P8_BASE64`
- Secret: paste (⌘V)

If you no longer have the file, make a new key at App Store Connect → Users and Access → Integrations → App Store Connect API → **+**, with the **Admin** role, and download it. Then add two repository **variables** next to the secret: `ASC_KEY_ID` (the new key's ID) and `ASC_ISSUER_ID` (shown above the keys list).

The key needs the **Admin** role, because automatic signing creates certificates and profiles.

### 2. Create the app in App Store Connect

Apple only allows this on the website. Run the workflow once first: it registers the bundle ID `com.mojo.sdahymnal` for you, then stops and says the app is missing. Then go to [App Store Connect → Apps](https://appstoreconnect.apple.com/apps) → **+** → **New App**:

| Field | Value |
| --- | --- |
| Platform | iOS |
| Name | SDA Hymnal (if it's taken, try "SDA Hymnal by Mojo") |
| Primary language | English (U.K.) |
| Bundle ID | com.mojo.sdahymnal |
| SKU | sdahymnal |
| User access | Full access |

### 3. Run it

Go to **Actions → TestFlight → Run workflow** (or push to `main`). A build takes 20–35 minutes. When it says "uploaded", Apple processes it for another 5–30 minutes, and then it appears under **App Store Connect → SDA Hymnal → TestFlight**.

### 4. Testers

- **Internal** (you and your team, up to 100 people): TestFlight → Internal Testing → **+** → add yourself. Builds arrive straight away.
- **External** (anyone, by email or public link): make a group under External Testing. The first build needs Apple's beta review (usually under a day). Apple will ask for a short description and a contact email.

Encryption: the app declares that it uses no non-exempt encryption, so TestFlight won't ask the export-compliance question.

## When a build fails

The run's logs are saved to the `ci-logs` branch (`check/` and `testflight/`), and `status.txt` in each says where it stopped. Common causes:

- **"ASC_KEY_P8_BASE64 secret isn't set"**: do step 1.
- **"create the app in App Store Connect first"**: do step 2, then run it again.
- **Key turned away (401/403)**: the key was revoked or doesn't have the Admin role; make a new one (step 1).
- **Build number already used**: run the workflow again; each run uses a higher number.
- **"The job was not acquired by Runner"**: GitHub had no Mac free. Run it again, and pick **macos-15-intel** under "Which GitHub Mac" if it keeps happening.
