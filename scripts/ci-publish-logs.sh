#!/bin/bash
# Saves this run's logs to the ci-logs branch (under <job>/), so they can be read with git as well as on
# the Actions page. $1 = the job's name. Never fails the job.
set -u
JOB="${1:-job}"
LOG_DIR="${LOG_DIR:-$RUNNER_TEMP/logs}"
[ -d "$LOG_DIR" ] || exit 0
REPO="https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
W="$RUNNER_TEMP/logrepo"
rm -rf "$W"
if ! git clone --quiet --depth 1 --branch ci-logs "$REPO" "$W" 2>/dev/null; then
  mkdir -p "$W" && cd "$W" && git init -q -b ci-logs && git remote add origin "$REPO" && cd - > /dev/null
fi
rm -rf "$W/$JOB" && mkdir -p "$W/$JOB" && cp -R "$LOG_DIR"/. "$W/$JOB/"
echo "run ${GITHUB_RUN_NUMBER:-?} (${GITHUB_RUN_ID:-?}) at ${GITHUB_SHA:-?}" > "$W/$JOB/run.txt"
cd "$W" && git add -A && git -c user.name="CI logs" -c user.email="ci@users.noreply.github.com" commit -qm "$JOB logs, run ${GITHUB_RUN_NUMBER:-?}" && git push -q origin ci-logs 2>/dev/null || true
exit 0
