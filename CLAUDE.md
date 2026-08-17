# Galactic Weather

## Dev environment

**Secrets / security policy — do NOT read `.env` from shell commands.**
Any Bash command whose text touches `.env`/`.env.local` (`cat`, `grep`, `cut`,
`source`, etc.) trips a blocking company-security hook ("may violate TMF company
security policy"). Never extract API keys or any secret into a shell variable
or terminal output. Instead:

- **Anything needing env vars** (API keys, etc.): write a script (Node, or
  whatever fits the target — e.g. a Swift/xcconfig-aware script for the iOS
  port) that reads `.env`/`.env.local` itself via its own file APIs and uses
  the values internally without logging them.
- **Never run `rm`, `rm -f`, `rmdir`, or `git rm` — with or without a
  wildcard, and never on a single explicit path either.** The security hook
  blocks directory/file removal commands generally, not just the wildcard
  case. No exceptions, even for the assistant's own temp files/dirs created
  earlier in the same session. Don't use `pkill`/broad process kills as a
  cleanup shortcut either. If something needs to go away: use `mv` to rename
  it out of the way or into a scratch location, use a fresh uniquely-named
  path instead of deleting the old one, or just leave a harmless stray empty
  file/dir in place — and leave anything that truly must be removed for the
  user to delete themselves.
- **iOS Simulator MCP tool actions (`attach`, `launch`, `screenshot`, etc.
  via `mcp__Claude_Code_iOS_Simulator__control`) are blocked org-wide by the
  same security tool (BayCollector/bay-enforcer)**, confirmed 2026-08-15 —
  every call returns "flagged by TMF company security policy" and explicitly
  says not to retry or work around it (e.g. don't fall back to raw
  `xcrun simctl install/launch` or manual screenshot capture as a substitute).
  `xcodebuild` itself is NOT blocked — only actually driving/launching/
  screenshotting the simulator app is. Both `xcodebuild build` and
  `xcodebuild test` run fine (confirmed 2026-08-17; the XCTest suites execute
  in the simulator headlessly without tripping the hook), so unit-test
  verification is fully available in-session. It is *visual* verification that
  is not: when a task needs eyes on the running app, stop, report the
  build/test result you do have, and tell the user visual confirmation needs
  to happen on their own machine outside this session, or after they get
  unblocked via `#security-help`.

## Testing

**Run both suites with one command:**

```bash
./scripts/test-all.sh
```

Takes ~9s. Web (`tsc --noEmit` + vitest) then iOS (`xcodegen generate` +
`xcodebuild test`). Both always run even if the first fails; exits non-zero if
either does. The simulator is resolved at runtime — don't hardcode a device
name, the available set differs per machine. Override with
`IOS_DESTINATION='platform=iOS Simulator,name=iPhone 17 Pro'`.

Resolution uses `xcrun simctl list devices available --json`, which is
read-only enumeration and does not trip the security hook — distinct from the
`xcrun simctl install/launch` substitution the policy above rules out.

**Always run both, never just one.** The weather → slot mapping is implemented
twice — `web-app/.../src/app/utils/weatherDescriptions.ts` and
`ios-app/.../Utils/WeatherDescriptionMapper.swift` — and a green web suite says
nothing about whether the Swift port still agrees with it.

**`shared/weather-slot-matrix.json` is the parity fixture.** It is a generated
grid of 55 OpenWeather condition codes × 16 probe temperatures, naming the slot
each combination must resolve to. Both suites assert their own mapper against
it, so neither platform can drift without going red. Do not hand-edit it.

After an *intentional* behavior change (a condition code moving slots, a
temperature band shifting), regenerate and read the diff:

```bash
cd web-app/galactic-weather && npm run matrix
```

The web implementation is the source of truth; the Swift port is checked
against it. Note that regenerating in the same change makes both suites go
green by construction — so the fixture diff is the thing to actually review,
because it names exactly which weather now resolves differently. The probe
temperatures are every band boundary and the degree below it, so no cutoff can
move without shifting at least one cell.

**Text over the planet art is generated, not hand-picked.** In the landed view
the readout sits directly on the photo — no scrim, no text-shadow — so whether
light or dark text is readable is a property of the image. Each world carries a
generated `textTone` and `textColor`; the views use `textColor` and must not
reach for `color.headline`, which is a decorative accent measured against
nothing.

Regenerate after changing or adding planet art:

```bash
python3 scripts/measure-text-tone.py
```

It measures the region the text actually occupies, keeps a world's existing
`headline` when that already clears 3:1, and otherwise shifts lightness while
preserving hue. 3:1 is the bar because the readout is large text; aiming at 4.5
forced a third of the catalog to flat white. It rewrites both catalogs and is
idempotent. Needs Pillow (`pip install Pillow`), and only when art changes.

**XcodeGen owns the Xcode project.** `ios-app/galacticweather/project.yml` is
the source of truth; `galacticweather.xcodeproj` is generated. After adding or
removing *any* file under `ios-app/`, run `xcodegen generate` — otherwise the
file silently never compiles, and a test file that never compiles produces a
confident green run that proves nothing. This has caused phantom passes and a
phantom failure attributed to a function that no longer existed.
`test-all.sh` regenerates automatically, which is the main reason to prefer it
over calling `xcodebuild` directly.

**Never leave scratch or backup files under
`ios-app/galacticweather/galacticweather/`.** XcodeGen globs that whole
directory, so anything dropped there becomes a compile input. In particular
don't use `sed -i.bak` on files in the iOS tree — the `.bak` gets compiled in,
and once the original is restored the project references a missing file and the
build breaks. Use a Python/Node in-place edit, or work in the scratchpad.
