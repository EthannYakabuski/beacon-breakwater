# Beacon Breakwater continuation

## Round 5 continuation

Work only on the requested Round 5 Beacon changes: chance icons, direct watch launch and a gradual endless opening. Do not start new games or change other projects. The current Android default is Gradle **AAB**, min API **24** / target API **36**, with ARM64, x86 and x86_64. Follow the [Round 4 Android guide](docs/ROUND_FOUR_ANDROID.md) for current export instructions instead of older APK examples in historical guides.

The 2026-10-24 continuation snapshot does not claim passing exact-current-source CI or native acceptance for rebuilt Round 4 binaries. Record later source-bound checks in `HANDOFF.txt`; keep all dated original APK evidence intact. Debug AABs are test-signed bundles, distinct from owner-signed releases. Preserve user configuration and untracked files.

The folder containing this file is the active development working copy. Earlier
staging copies and preserved originals are archives, not parallel edit locations.
Start a focused task for this game; do not assume access to an earlier chat.

1. Read `README.md`, `HANDOFF.txt`, `docs/DEVELOPER.md` and
   `docs/PLATFORM_SETUP.md` before changing integration or release configuration.
2. Inspect `git status`, the current branch and `origin`. The intended repository
   is `https://github.com/EthannYakabuski/beacon-breakwater`. Preserve user edits
   and local artifacts. Do not reset, clean or overwrite them to obtain a clean
   status.
3. Read the requested change, relevant source and existing tests. Keep the work
   scoped to this game and document the resulting behavior and verification.

Godot 4.5.1 Compatibility is the engine baseline. Android is primary; Web uses
single-threaded export and native-service fallbacks. The observed export setup
is minimum API 24 / target API 36, not a current Google Play eligibility claim.
Use matching export templates and the existing Android preset.

Read `docs/ROUND_FIVE.md` for current behavior and acceptance checks. Preserve owner artwork/configuration and keep dated native evidence tied to its original binary.

`game/watch.gd` owns deterministic play, `game/profile.gd` banked accounting and
`game/save_store.gd` atomic storage. Preserve once-only banking, assisted-record
rules, stale-callback protection and the explicit Resume after fullscreen ads.
An earned callback must not resume combat behind a native endcard. Offline/Web
fallbacks must not manufacture an earned reward.

Service configuration is in `platform/config.json`; the 26 achievement and four
leaderboard keys/metrics/icons are in `game/catalog.json`. Play Games also needs
the matching numeric `godot_play_game_services/game_id` in the Android export
preset. Its mappings are blank and integration is disabled until configured.
For AdMob, `admob.app_id` in JSON is reference metadata: the Android manifest
uses Godot Project Settings `admob/general/android/app_id` in `project.godot`.
Configured ad unit IDs are used as supplied. `test_mode` changes status wording;
it does not turn production IDs into test requests or register test devices.

Run only relevant checks, using isolated temporary user-data directories for
Godot and the service pending store. The UI test requires `--qa-isolated`.
Never use real player saves as test fixtures. Keep strict error checks intact;
report a failed diagnostic honestly rather than filtering it out.

`HANDOFF.txt` distinguishes the original native-tested APK from separately built
CI artifacts. Documentation-only updates do not require rebuilding that APK.
Keep build outputs, real saves, private QA logs, machine records, signing keys
and credentials out of Git. Ignore rules do not protect already tracked files;
review staged paths and diffs before each commit. Keep `LICENSE`, `NOTICE` and
the complete `LICENSES/` tree with redistributions.

Production IDs/configuration, signing, consent/store declarations, physical and
audible testing, interactive Web and human balance acceptance remain follow-up
work. No Google Play publication, live Pages activation or Library operation is
part of an ordinary source update. Do not start another application from this
game's task. Report exact commits, tests and remaining limits when handing off.
