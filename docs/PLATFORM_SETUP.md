# Platform setup and real IDs

## Current Round 4 Android export

The preset currently uses minimum API **24** / target API **36**, Gradle **AAB**, and ARM64, x86 and x86_64. These settings are configurable choices, not a fixed Godot target-SDK limit. Follow the [Round 4 Android guide](ROUND_FOUR_ANDROID.md); create a new unused output directory, export a debug `.aab`, then run `tools/verify_android_bundle.py` on the actual bundle.

The debug AAB is test-signed; release signing stays with the owner outside Git. ABI validation alone does not establish native gameplay, production services or Google Play acceptance. Focused music pause-state source `3778721a06453ec4626804681efdff3e121eb7ec` has [passing exact-commit hosted CI](https://github.com/EthannYakabuski/beacon-breakwater/actions/runs/40146765415). Local Android bundle acceptance and bounded Web003 behavior are separate; see `../HANDOFF.txt` for the actual component identities and qualified test package. Affected native acceptance remains unverified. Preserve historical APK/native QA identities; no new-game work is authorized by this continuation.

Godot 4.5.1 Compatibility, matching templates, JDK 17 and the Android SDK are the
baseline. Android is primary; Web runs without simulated native rewards. Current
min API 24 / target API 36 is the current preset configuration and must be checked
against release requirements before publication. Keep the existing package name
`com.ethannyakabuski.beaconbreakwater` when linking its console app.

## Google Play Games Services

`game/catalog.json` defines 26 achievements and four leaderboards using `key`
fields, metrics and icon paths. Preserve these symbolic keys when adding console
IDs; their spelling connects gameplay to the Services adapter.

1. Create/configure the linked game and Android application in Play Console.
   Configure tester access, OAuth and signing certificate fingerprints for the
   actual debug/release application being tested. Keep signing material private.
2. Create the achievements and leaderboards from the catalog definitions/icons.
   Map each returned console ID into `platform/config.json` under
   `play_games.achievements.<key>` or `play_games.leaderboards.<key>`.
3. Put the numeric game ID into `play_games.game_id` in that JSON and the same
   value in `export_presets.cfg`, Android options
   `godot_play_game_services/game_id`. The current preset placeholder is `"0"`.
4. Change `play_games.enabled` to `true` only for a configured test build. Verify
   sign-in and each relevant unlock/score path with a linked tester account.

The six additional `coast7` through `coast12` mappings extend the existing twenty
achievement keys; preserve any owner-supplied existing IDs when adding them.

All real mappings currently remain blank and PGS is disabled. The adapter queues
pending progress while unavailable; tests of symbolic callbacks do not prove a
production service configuration. A cloud saved-games backend is not implemented;
the banked local profile remains authoritative.

## AdMob: app ID and ad unit IDs are separate

Current development uses Google's sample Android App ID and banner/interstitial/
rewarded unit IDs. In `platform/config.json`, `admob.banner_unit_id`,
`interstitial_unit_id` and `rewarded_unit_id` are the IDs actually passed to the
loaders by `platform/services.gd`.

The JSON `admob.app_id` is reference metadata: no game/platform script reads it.
The vendored exporter obtains the Android manifest App ID from Godot Project
Settings `admob/general/android/app_id`. Set it through the editor or serialize
the setting in `project.godot` as:

```ini
[admob]

general/android/app_id="<your Android AdMob App ID>"
```

Do not paste the placeholder literally into a build. Current `project.godot`
omits an override, so the plugin's default is Google's sample App ID. If moving
to an owner App ID, update the JSON reference value consistently and verify the
exported manifest as well as the actual ad unit configuration.

`admob.test_mode` currently changes the Services status text only. `_ad_id()`
returns configured unit IDs unchanged. Keeping this flag true while entering
production unit IDs does not make requests test requests and does not register
test devices. Keep sample unit IDs for development, or configure/verify the
SDK's documented test-device mechanism before using owner units. Production IDs,
consent, audience/under-age settings, privacy policy and store declarations need
the owner's actual configuration and device verification.

## Reward and lifecycle checks

Consent gates initialization. Menu banner reserve follows actual measured native
space. Every two natural completed watches advances interstitial cadence;
abandonment does not. One earned rescue flare can guide the visible fleet per
watch. A lost watch can offer one earned continue that restores its actual lost
fleet and marks the watch assisted; an unearned dismissal cannot restore it. Fullscreen content and pending requests keep play paused even after an
earned callback; dismissal returns to Pause and explicit Resume is required.
Missing services, offline mode and Web must not fabricate an earned reward.

See `../HANDOFF.txt` and `NATIVE_QA.json` for the exact tested artifact and remaining
limits. After ID changes, produce a separately named build and test actual native
flows; do not relabel the preserved sample-configured APK as production-tested.
Google Play submission, live Pages activation and Library actions are separate
owner-authorized work, not part of ordinary ID editing.
