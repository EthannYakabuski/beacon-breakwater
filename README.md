# Beacon Breakwater

A portrait lighthouse rescue arcade built with Godot 4.5.1 Compatibility. Sweep
one beam over drifting vessels, establish their guidance and bring a fleet home.
Sixty watches across twelve coasts, an endless watch and a daily watch share the
same deterministic rescue rules.

## Round Three export candidate

Runtime `b71583c14a7fbaddb05f6faed5bd24cda970f8de` has accepted local Android/Web test exports under `build/round-three-b71583c1-a1/` and [exact-source CI SUCCESS](https://github.com/EthannYakabuski/beacon-breakwater/actions/runs/39795036517). Artifact paths/full hashes are in `HANDOFF.txt`; [Round Three rules](docs/ROUND_THREE.md) explain the changed rings and harbor approach. Native testing and six screenshots per profile remain pending behind task-emulator System UI failure. These exports are not a completed Round Three native handoff. Historical Round Two evidence below retains its original scope.

## Play

Drag anywhere over the water to aim the light. Keep a boat inside its beam until
the inner guidance ring fills and the vessel starts steering home. Its outer
ring stays green only while currently illuminated and continues draining slowly.
Off-beam guided boats turn gold (red when urgent), drain faster and return to
normal speed; never-guided boats drain fastest. More hull coverage gives more
speed. Guided boats keep full speed during their final harbor approach, without
extra ring protection. The outer ring is the remaining budget before loss.
Red emergency marks signal priority. The free foghorn slows danger and recharges. Pause is always available.
Desktop development controls: mouse drag, left/right arrows, Space for foghorn,
Escape for Back. Android touch is the primary interface.

Coins and keeper XP improve lens width, focus speed, harbor guidance time,
foghorn reserves and breakwater shelter.
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
godot --headless --path . --script tests/test_round_two.gd
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
An earned optional rescue flare guides the visible fleet once per watch. A lost
watch can offer one earned continue that recovers its actual lost fleet and marks
the watch assisted. Leaving a continuable loss banks that completed result once. Play
stays paused through native fullscreen content and requires explicit Resume.
Offline/Web/unavailable services do not simulate an earned reward.

Play Games is disabled with blank real-ID mappings. Configure the 26 achievements
and four boards in `platform/config.json`, using the symbolic keys and metrics in
`game/catalog.json`, and set the matching numeric PGS game ID in the Android
export preset. AdMob needs both its JSON ad unit IDs and its manifest App ID in
Godot Project Settings. JSON `app_id` alone does not change the manifest;
`test_mode` alone does not make production ads test requests. Exact steps are in
[platform setup](docs/PLATFORM_SETUP.md).

## Store package and verification

Round Two replaces app/feature, all 26 achievement icons and all four leaderboard
icons with distinct generated illustrations. Originals, prompts and SHA256
provenance are retained under `marketing/source-art`; standard 512px packaging
was inspected at final size and at 64px. Illustrations are not screenshots.
Nine approved final-build native screenshots are under
`marketing/screenshots-round-two`, with relative PNG hashes and display profiles
in its `capture-manifest.json`. Earlier screenshots remain unchanged under
`marketing/screenshots` and retain their original APK scope. No physical-tablet
test is claimed.

The Round Two local handoff is ready with documented limits. Native body-touch
scrolling, ordinary play, a real earned loss continue held86.55seconds behind its
endcard, explicit Resume, assisted/unassisted once-only banking, Focus purchase,
Back and actual offline/cold save retention passed. All18 banked groups and
pending service-store semantics survived the observed final checks. The initial
missing AVD package was recovered from a verified genuine legacy backup before
the tested updates; retention across that earlier session loss is not claimed.

Preserved Round Two runtime commit: `725c4cac38fc071639d673f11ca37b1667c663ba`.
Local APK: `build/round-two-725c4cac-a1/android/beacon-breakwater-debug.apk`
(194578012bytes), SHA256 `C0DF2CED4DD0142B563527AF3D650A1BDFA95B96F19859176D32E54953D7809D`.
Web bundle: `build/round-two-725c4cac-a1/web/index.html` plus its sidecars/notices.
Strict exports passed with stable inputs and verified source binding. Interactive
Web remains unverified. The dated Round Two handoff recorded a push denial; the current Round Three exact-source CI result is linked above.

`HANDOFF.txt`, `docs/NATIVE_QA.json` and `docs/LOCAL_TEST_RESULTS.json` distinguish
this exact build from historical packages. The untouched original native-tested
APK remains at `build/android/game-debug.apk` (SHA256
`82C96A5725B1BED9F341F42540F316587DD7FE9433937057424555F1A9C447E1`). Hosted CI artifacts are
separate binaries. See [Round Two behavior and verification](docs/ROUND_TWO.md).

Physical devices, audible Android output, interactive Web/audio/WebGL, production
services and human balance remain unverified. Real IDs, backend/signing,
privacy/contact/consent/store declarations and Google Play publication are owner
work. See `marketing/RELEASE-CHECKLIST.txt` for release preparation.

## License

Original code, authored content, generated harbor illustrations and composed music
are Apache-2.0. Kenney Pirate Pack, UI Pack, UI SFX and Interface Sounds assets
are CC0-1.0. Native
plugins and Godot components retain their own notices. Keep `LICENSE`, `NOTICE`
and the complete `LICENSES/` directory with redistributed source and builds.
No Creature Mixer asset is used in this game.

Round Three ring phases and the explicit nonzero illuminated-rate assumption
are documented in [docs/ROUND_THREE.md](docs/ROUND_THREE.md). Source changes do
not relabel the historical native-tested APK or screenshots as a new build.
