#!/usr/bin/env bash
#
# Builds a Release archive of the iOS app, ready to upload to App Store Connect.
#
#   ./scripts/archive.sh
#   ./scripts/archive.sh --export        # also export a signed .ipa
#   ./scripts/archive.sh --skip-tests    # skip the suites (not recommended)
#   ./scripts/archive.sh --yes           # accept confirmations (for non-interactive runs)
#
# Uploading is deliberately NOT automated — see TESTFLIGHT.md. That step needs
# App Store Connect credentials, and Xcode's Organizer does it reliably in three
# clicks. This script's job is to produce an archive you can trust.
#
# The preflight is the useful part. It refuses to build when the result would be
# a wasted TestFlight round:
#
#   - No Secrets.xcconfig            -> the app cannot fetch weather at all.
#   - No TELEMETRYDECK_APP_ID        -> the build ships with analytics OFF, so
#                                       the whole round produces no data. This
#                                       is the quiet one, and the expensive one.
#   - Dirty working tree             -> the archive won't correspond to a commit.
#
# Secret VALUES are never read into the shell or printed. The check is done by a
# Python helper that reads the file itself and reports booleans, per the policy
# in CLAUDE.md.

set -uo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
IOS_DIR="$REPO_ROOT/ios-app/galacticweather"
SECRETS="$IOS_DIR/Config/Secrets.xcconfig"
SCHEME="galacticweather"

if [[ -t 1 ]]; then
	BOLD=$'\033[1m'; RED=$'\033[31m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; DIM=$'\033[2m'; OFF=$'\033[0m'
else
	BOLD=''; RED=''; GREEN=''; YELLOW=''; DIM=''; OFF=''
fi

do_export=0
skip_tests=0
assume_yes=0
for arg in "$@"; do
	case "$arg" in
		--export)     do_export=1 ;;
		--skip-tests) skip_tests=1 ;;
		--yes|-y)     assume_yes=1 ;;
		-h|--help)    sed -n '2,26p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
		*)            echo "${RED}unknown argument: $arg${OFF}"; exit 2 ;;
	esac
done

fail() { echo "${RED}$1${OFF}"; exit 1; }

# read -p blocks forever when there is no terminal (CI, pipes, an agent session).
# Refuse rather than hang; --yes opts into every confirmation up front.
confirm() {
	local prompt="$1"
	if [[ $assume_yes -eq 1 ]]; then
		echo "  ${DIM}$prompt -> yes (--yes)${OFF}"
		return 0
	fi
	if [[ ! -t 0 ]]; then
		fail "$prompt
  No terminal to ask on. Re-run interactively, or pass --yes to accept."
	fi
	read -r -p "  $prompt [y/N] " reply
	[[ "$reply" == "y" || "$reply" == "Y" ]]
}

# ── preflight ───────────────────────────────────────────────────────────────
echo "${BOLD}preflight${OFF}"

command -v xcodegen >/dev/null || fail "xcodegen not installed — brew install xcodegen"

[[ -f "$SECRETS" ]] || fail "missing $SECRETS
  Copy Config/Secrets.xcconfig.example and fill it in. Without
  OPENWEATHERMAP_API_KEY the app cannot fetch a forecast, so the build is
  useless to a tester."

# Reads the file in-process and reports only key names and booleans — never values.
secrets_report=$(python3 - "$SECRETS" <<'PY'
import sys, re
path = sys.argv[1]
want = ["OPENWEATHERMAP_API_KEY", "TELEMETRYDECK_APP_ID"]
found = {}
with open(path, encoding="utf-8", errors="replace") as fh:
    for line in fh:
        line = line.split("//", 1)[0].strip()
        m = re.match(r"^([A-Z0-9_]+)\s*=\s*(.*)$", line)
        if m:
            found[m.group(1)] = bool(m.group(2).strip())
for k in want:
    print(f"{k}={'set' if found.get(k) else 'MISSING'}")
PY
)

weather_ok=0
telemetry_ok=0
while IFS='=' read -r key state; do
	case "$key:$state" in
		OPENWEATHERMAP_API_KEY:set)  weather_ok=1;   echo "  ${GREEN}✓${OFF} OPENWEATHERMAP_API_KEY set" ;;
		OPENWEATHERMAP_API_KEY:*)                    echo "  ${RED}✗${OFF} OPENWEATHERMAP_API_KEY missing" ;;
		TELEMETRYDECK_APP_ID:set)    telemetry_ok=1; echo "  ${GREEN}✓${OFF} TELEMETRYDECK_APP_ID set" ;;
		TELEMETRYDECK_APP_ID:*)                      echo "  ${YELLOW}!${OFF} TELEMETRYDECK_APP_ID missing" ;;
	esac
done <<< "$secrets_report"

[[ $weather_ok -eq 1 ]] || fail "OPENWEATHERMAP_API_KEY is not set in Secrets.xcconfig — nothing to ship."

if [[ $telemetry_ok -eq 0 ]]; then
	echo
	echo "${YELLOW}${BOLD}Analytics will be OFF in this build.${OFF}"
	echo "${DIM}  Services/Analytics.swift sends nothing unless TELEMETRYDECK_APP_ID is set,"
	echo "  so a TestFlight round built this way tells you nothing about whether"
	echo "  anyone came back. See MEASUREMENT.md — that is the one thing the round"
	echo "  is for. Set it, or continue knowingly.${OFF}"
	echo
	confirm "Continue without analytics?" || fail "stopped — set TELEMETRYDECK_APP_ID and re-run."
fi

# An archive should correspond to a commit, or you cannot tell later what a
# tester was actually running.
if [[ -n "$(git -C "$REPO_ROOT" status --porcelain)" ]]; then
	echo "  ${YELLOW}!${OFF} working tree is dirty — this archive won't match any commit"
	git -C "$REPO_ROOT" status --porcelain | sed 's/^/      /'
	confirm "Continue with a dirty tree?" || fail "stopped — commit first."
else
	echo "  ${GREEN}✓${OFF} clean tree at $(git -C "$REPO_ROOT" rev-parse --short HEAD)"
fi

version=$(grep -E '^\s*MARKETING_VERSION:' "$IOS_DIR/project.yml" | head -1 | sed -E 's/.*"(.*)".*/\1/')
build=$(grep -E '^\s*CURRENT_PROJECT_VERSION:' "$IOS_DIR/project.yml" | head -1 | sed -E 's/.*"(.*)".*/\1/')
echo "  ${DIM}version $version, build $build${OFF}"
echo "  ${DIM}App Store Connect rejects a build number it has already seen —"
echo "  bump CURRENT_PROJECT_VERSION in project.yml, not in Xcode.${OFF}"
echo

# ── tests ───────────────────────────────────────────────────────────────────
if [[ $skip_tests -eq 0 ]]; then
	echo "${BOLD}tests${OFF} ${DIM}— refusing to archive on red${OFF}"
	"$REPO_ROOT/scripts/test-all.sh" || fail "suites failed — not archiving."
	echo
else
	echo "${YELLOW}skipping tests${OFF}"
	echo
fi

# ── archive ─────────────────────────────────────────────────────────────────
# Archives go into Xcode's own Archives folder, NOT into the repo.
#
# Organizer only lists archives found under ~/Library/Developer/Xcode/Archives,
# in a folder named for the day. An archive anywhere else does not appear there —
# which means "Distribute App" is nowhere to be found, because Distribute App is
# a button on the Organizer row that does not exist. Writing to build/archives/
# produced exactly that dead end, and the fix was copying the archive in by hand
# afterwards, which is a step nobody remembers.
#
# The optional --export .ipa still lands in the repo under build/, since that one
# is for feeding Transporter and you want it somewhere you can find.
#
# Unique path per run. Nothing is ever deleted here — see the deletion policy in
# CLAUDE.md; old archives are left for you to clear by hand.
stamp=$(date +%Y%m%d-%H%M%S)
ARCHIVE_ROOT="$HOME/Library/Developer/Xcode/Archives/$(date +%Y-%m-%d)"
ARCHIVE="$ARCHIVE_ROOT/galacticweather-$version-$build-$stamp.xcarchive"
OUT_DIR="$REPO_ROOT/build"
mkdir -p "$ARCHIVE_ROOT" "$OUT_DIR"

echo "${BOLD}archive${OFF} ${DIM}— xcodegen generate + xcodebuild archive (Release)${OFF}"
log=$(mktemp -t galactic-archive)

if (cd "$IOS_DIR" && xcodegen generate >/dev/null && \
	xcodebuild archive \
		-scheme "$SCHEME" \
		-configuration Release \
		-destination 'generic/platform=iOS' \
		-archivePath "$ARCHIVE" \
		-allowProvisioningUpdates) >"$log" 2>&1; then
	echo "  ${GREEN}✓${OFF} $ARCHIVE"
else
	echo "  ${RED}archive failed${OFF}"
	grep -E "error:|error$|Provisioning|Signing|failed" "$log" | tail -25
	echo "${DIM}full log: $log${OFF}"
	echo
	echo "${DIM}If this is a provisioning failure, the usual cause is the App ID"
	echo "not having iCloud Key-Value Storage enabled. Config/galacticweather.entitlements"
	echo "requests com.apple.developer.ubiquity-kvstore-identifier, and automatic"
	echo "signing cannot invent a profile for a capability the App ID lacks."
	echo "See TESTFLIGHT.md, Part 1.${OFF}"
	exit 1
fi
echo

# ── export (optional) ───────────────────────────────────────────────────────
if [[ $do_export -eq 1 ]]; then
	echo "${BOLD}export${OFF} ${DIM}— xcodebuild -exportArchive${OFF}"
	PLIST="$OUT_DIR/ExportOptions.plist"
	if [[ ! -f "$PLIST" ]]; then
		cat >"$PLIST" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key>
	<string>app-store-connect</string>
	<key>teamID</key>
	<string>WNJ76895SD</string>
	<key>uploadSymbols</key>
	<true/>
	<key>destination</key>
	<string>export</string>
</dict>
</plist>
XML
		echo "  ${DIM}wrote $PLIST${OFF}"
		echo "  ${DIM}If xcodebuild rejects method 'app-store-connect', your Xcode wants"
		echo "  the older value 'app-store' — edit the plist and re-run.${OFF}"
	fi

	IPA_DIR="$OUT_DIR/ipa-$version-$build-$stamp"
	if (cd "$IOS_DIR" && xcodebuild -exportArchive \
			-archivePath "$ARCHIVE" \
			-exportOptionsPlist "$PLIST" \
			-exportPath "$IPA_DIR" \
			-allowProvisioningUpdates) >>"$log" 2>&1; then
		echo "  ${GREEN}✓${OFF} $IPA_DIR"
	else
		echo "  ${RED}export failed${OFF}"
		grep -E "error:|Provisioning|Signing" "$log" | tail -20
		echo "${DIM}full log: $log${OFF}"
		exit 1
	fi
	echo
fi

# ── next ────────────────────────────────────────────────────────────────────
echo "${BOLD}next${OFF}"
echo "  In Xcode: ${BOLD}Window -> Organizer -> Archives${OFF}, pick"
echo "  ${DIM}galacticweather-$version-$build${OFF}, then ${BOLD}Distribute App${OFF}."
echo
echo "  ${DIM}Distribute App is a button on the Organizer row, so the archive has to"
echo "  be somewhere Organizer looks — which is why this wrote to"
echo "  ~/Library/Developer/Xcode/Archives rather than into the repo:"
echo "    $ARCHIVE${OFF}"
echo
echo "  Then follow TESTFLIGHT.md from Part 4."
