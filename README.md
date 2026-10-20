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

## Run and build

Open `project.godot` in Godot 4.5.1 and run `main.tscn`. Android and Web presets are
included; Android requires the engine's matching templates, JDK17 and Android SDK.
The current engine export configuration is min API24 / target API35. This is an
observed engine constraint, not a claim of current Google Play release eligibility.
No Windows distribution build is part of this project.

```
godot --headless --editor --path . --import
godot --headless --path . --script tests/test_models.gd
godot --headless --path . --script tests/test_ui.gd -- --qa-isolated
godot --headless --path . --export-release Web build/web/index.html
godot --headless --path . --install-android-build-template --export-debug Android build/android/game-debug.apk
```

Run tests in an isolated user directory. The UI test uses a distinct QA save name
and never opens the production harbor save. The shared platform's pending-service
store should also be isolated when running the full project in a test harness.
The hosted workflow builds test-configured artifacts and copies notices. Pages
deployment is intentionally absent until the coordinator separately authorizes it.

## Optional native services

Actual Google Play Games Services and Poing AdMob plugins are vendored. Official
Google Android test app/banner/interstitial/rewarded IDs are configured. Consent
handling gates ad initialization. Home reserves the measured banner/safe-area
space; a natural completed watch advances interstitial cadence every two rounds.
An earned optional rescue flare guides the visible fleet once per watch. Web,
offline and unavailable services never simulate a reward.

The simulation stays paused throughout pending requests, application suspension
and native fullscreen content. An SDK earned callback can apply assistance while
the endcard is open, but it cannot resume play. Explicit Resume is required.

Play Games is disabled until the owner supplies its game ID, achievement IDs and
leaderboard IDs in `platform/config.json`, matching the symbolic keys in
`game/catalog.json`. See [developer configuration](docs/DEVELOPER.md). Production
AdMob/PGS/backend/consent/signing and real-service testing remain owner work.

## Store package and evidence

`marketing/` contains app/feature illustrations, twenty achievement icons, four
leaderboard icons and store/Web copy. These illustrations are not screenshots.
Actual normal-play phone and logical7/10 captures, Android/native acceptance and
interactive Web QA are coordinator-owned checks. Read the current QA report for
what has actually run; source and model tests do not establish physical-device,
audible-sound, production-service or human-fun acceptance.

## License

Original code, authored content, code-drawn illustrations and synthesized ambient
audio are Apache-2.0. Kenney Pirate Pack and UI SFX Set assets are CC0-1.0. The
native plugins and Godot components retain their own notices. Keep `LICENSE`,
`NOTICE` and the complete `LICENSES/` directory with redistributed source and
builds. No Creature Mixer asset is used in this game.

## Public source and deployment status

This source copy includes code, assets, tests, store materials and sanitized summaries of dated local checks. It contains no real profile saves, private SDK/runtime ledgers, signing identities, credentials or prebuilt exports. Build/test/artifact CI is configured; a Pages deployment job is absent and live deployment remains held. Production services, physical-device/audio/browser checks and human playtesting remain separate work. Original work is Apache-2.0; third-party assets, engine, fonts and plugins keep their own notices in LICENSES.
