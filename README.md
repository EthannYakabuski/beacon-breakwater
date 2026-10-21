# Beacon Breakwater

A portrait lighthouse rescue arcade built with Godot 4.5.1 Compatibility. Sweep
one beam over drifting vessels, establish their guidance and bring a fleet home.
Thirty watches across six coasts, an endless watch and a daily watch share the
same deterministic rescue rules.

## Play

Drag anywhere over the water to aim the light. Keep a boat inside its beam until
the inner guidance ring fills. Green boats sail home safely; the outer ring shows
time remaining before an unescorted boat is lost. Red emergency marks signal
priority. The free foghorn slows danger and recharges. Pause is always available.
Desktop development controls: mouse drag, left/right arrows, Space for foghorn,
Escape for Back. Android touch is the primary interface.

Coins and keeper XP improve lens width, focus speed and harbor guidance time.
First mission clears, perfect watches, daily quests and seven-day login gifts
have explicit rewards. Assisted endless watches never replace the unassisted
record. Active watches are not resumable saves; only genuine banked progress is
stored with checksum, staged replacement and backup recovery.

## Continue development

Use this game's canonical working copy as its Codex project and start one focused
task per update. Read `AGENTS.md`, `HANDOFF.txt`, `docs/DEVELOPER.md` and
`docs/PLATFORM_SETUP.md`; a new task should not depend on inherited chat history.
Describe the requested behavior, relevant files, supplied console IDs and how to
verify completion. Preserve any existing changes before editing.

The public repository is
[EthannYakabuski/beacon-breakwater](https://github.com/EthannYakabuski/beacon-breakwater).
Before this continuation-documentation update, source commit
`ed10494e9c61bd3330b5fbd062adc97d5befe177` passed
[hosted build/test CI](https://github.com/EthannYakabuski/beacon-breakwater/actions/runs/39527175172),
including Android and Web exports. That dated result does not certify later
commits. Live Pages deployment is absent and remains held.

## Run and build

Open `project.godot` in Godot 4.5.1 and run `main.tscn`. Android and Web presets are
included; Android requires matching templates, JDK 17 and the Android SDK.
The current engine export configuration is min API 24 / target API 35. This is an
observed engine constraint, not a claim of current Google Play release eligibility.
No Windows distribution build is included.

```sh
godot --headless --editor --path . --import
godot --headless --path . --script tests/test_models.gd
godot --headless --path . --script tests/test_ui.gd -- --qa-isolated
godot --headless --path . --export-release Web build/web/index.html
godot --headless --path . --install-android-build-template --export-debug Android build/android/game-debug.apk
```

Run tests in isolated temporary user-data directories, including the shared
platform pending-service store. `--qa-isolated` gives the UI test a distinct QA
save, but is not a substitute for isolating all autoload storage. Do not point
tests at genuine profiles. The hosted workflow contains the build/test command
sequence and strict error gates; local native acceptance is documented separately.

## Optional native services

Google Play Games Services and Poing AdMob plugins are vendored with notices.
The current project uses Google's official sample app and ad unit IDs. Consent
handling gates ad initialization; Home reserves the measured banner/safe area.
Natural completed watches advance interstitial cadence every two rounds.
An earned optional rescue flare guides the visible fleet once per watch. Play
stays paused through native fullscreen content and requires explicit Resume.
Offline/Web/unavailable services do not simulate an earned reward.

Play Games is disabled with blank real-ID mappings. Configure the 20 achievements
and four boards in `platform/config.json`, using the symbolic keys and metrics in
`game/catalog.json`, and set the matching numeric PGS game ID in the Android
export preset. AdMob needs both its JSON ad unit IDs and its manifest App ID in
Godot Project Settings. JSON `app_id` alone does not change the manifest;
`test_mode` alone does not make production ads test requests. Exact steps are in
[platform setup](docs/PLATFORM_SETUP.md).

## Store package and verification

`marketing/` contains app/feature illustrations, 20 achievement icons, four
leaderboard icons and store/Web copy. Illustrations are not screenshots. Nine
reviewed ordinary-play phone and logical seven/ten-inch emulator screenshots are
in `marketing/screenshots`; they are not physical-tablet tests.

`HANDOFF.txt`, `docs/NATIVE_QA.json` and `docs/LOCAL_TEST_RESULTS.json` distinguish
current-build tests from historical tests and list remaining limits. The original
native-tested APK has SHA256
`82C96A5725B1BED9F341F42540F316587DD7FE9433937057424555F1A9C447E1`.
Where restored locally, it remains at `build/android/game-debug.apk`; prebuilt
exports and private QA evidence are not committed. CI binaries are separate
builds and have not received that original APK's native QA. No rebuild is needed
for this documentation-only continuation update.

Physical devices, audible Android output, interactive Web/audio/WebGL, production
services and human balance remain unverified. Real IDs, backend/signing,
privacy/contact/consent/store declarations and Google Play publication are owner
work. See `marketing/RELEASE-CHECKLIST.txt` for release preparation.

## License

Original code, authored content, code-drawn illustrations and synthesized ambient
audio are Apache-2.0. Kenney Pirate Pack and UI SFX Set assets are CC0-1.0. Native
plugins and Godot components retain their own notices. Keep `LICENSE`, `NOTICE`
and the complete `LICENSES/` directory with redistributed source and builds.
No Creature Mixer asset is used in this game.
