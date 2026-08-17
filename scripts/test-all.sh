#!/usr/bin/env bash
#
# Runs both test suites — the web app's vitest suite and the iOS XCTest suite.
#
# Both are needed for a meaningful pass: the weather → slot mapping is
# implemented twice, and shared/weather-slot-matrix.json is what keeps the two
# honest. Running only one half tells you nothing about parity.
#
#   ./scripts/test-all.sh
#
# The simulator is resolved automatically. Override it if you need a specific
# device:
#
#   IOS_DESTINATION='platform=iOS Simulator,name=iPhone 17 Pro' ./scripts/test-all.sh
#
# Exits non-zero if either suite fails. Both always run, so one failure does not
# hide the other's result.

set -uo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
WEB_DIR="$REPO_ROOT/web-app/galactic-weather"
IOS_DIR="$REPO_ROOT/ios-app/galacticweather"

if [[ -t 1 ]]; then
	BOLD=$'\033[1m'; RED=$'\033[31m'; GREEN=$'\033[32m'; DIM=$'\033[2m'; OFF=$'\033[0m'
else
	BOLD=''; RED=''; GREEN=''; DIM=''; OFF=''
fi

web_status=0
ios_status=0

# ── web ─────────────────────────────────────────────────────────────────────
echo "${BOLD}web${OFF} ${DIM}— tsc --noEmit + vitest${OFF}"
if ! (cd "$WEB_DIR" && npx tsc --noEmit && npm test --silent); then
	web_status=1
fi
echo

# ── iOS ─────────────────────────────────────────────────────────────────────
# Regenerate first. project.yml owns the Xcode project, so a source file added
# without a regenerate silently never compiles — which has produced phantom
# passes before.
echo "${BOLD}ios${OFF} ${DIM}— xcodegen generate + xcodebuild test${OFF}"

destination="${IOS_DESTINATION:-}"
if [[ -z "$destination" ]]; then
	device=$(xcrun simctl list devices available --json 2>/dev/null | python3 -c '
import json, sys
runtimes = json.load(sys.stdin)["devices"]
names = [d["name"] for rt in sorted(runtimes) if "iOS" in rt for d in runtimes[rt]]
iphones = [n for n in names if n.startswith("iPhone")]
print((iphones or names or [""])[0])
' 2>/dev/null)
	if [[ -z "$device" ]]; then
		echo "${RED}no iOS simulator available${OFF} — install one via Xcode, or set IOS_DESTINATION"
		ios_status=1
	else
		destination="platform=iOS Simulator,name=$device"
	fi
fi

if [[ $ios_status -eq 0 ]]; then
	echo "${DIM}destination: $destination${OFF}"
	log=$(mktemp -t galactic-ios-test)
	if (cd "$IOS_DIR" && xcodegen generate >/dev/null && \
		xcodebuild test -scheme galacticweather -destination "$destination") \
		>"$log" 2>&1; then
		grep -E "Executed [0-9]+ tests" "$log" | tail -1
	else
		ios_status=1
		# xcodebuild is enormously verbose; surface only what explains the failure.
		grep -E "error:|error$|failed:|Executed [0-9]+ tests|TEST FAILED" "$log" \
			| tail -25 || true
		echo "${DIM}full log: $log${OFF}"
	fi
fi
echo

# ── summary ─────────────────────────────────────────────────────────────────
label() { [[ $1 -eq 0 ]] && echo "${GREEN}pass${OFF}" || echo "${RED}fail${OFF}"; }
echo "${BOLD}web${OFF} $(label $web_status)   ${BOLD}ios${OFF} $(label $ios_status)"

if [[ $web_status -ne 0 || $ios_status -ne 0 ]]; then
	exit 1
fi
