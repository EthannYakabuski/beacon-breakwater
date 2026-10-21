# Developer continuation

This canonical game repository is the active working copy. Read `../AGENTS.md`
and `../HANDOFF.txt` from this directory's parent before starting a focused task;
do not rely on inherited chat. Inspect Git status and preserve existing edits.
The original local folders and raw QA evidence are retained as private archives.

## Runtime layout

Godot 4.5.1 Compatibility renders a portrait 540x960 logical stage with fitted
letterboxing. Android is primary; Web uses single-threaded rendering and safe
native-service fallbacks. Current exports use min API 24 / target API 35, which
does not establish present Google Play release eligibility.

- `game/watch.gd`: deterministic rescue simulation.
- `game/profile.gd`: banked accounting, bounded typed normalization, equipment,
  level bonuses and monotonic UTC-day rewards.
- `game/save_store.gd`: checksummed atomic saves and backup recovery.
- `game/main.gd`: touch UI, lifecycle pause, once-only result banking and native
  callbacks guarded against a stale run.
- `game/missions.json`: 30 curated traffic compositions across six coasts.
- `game/catalog.json`: 20 achievement definitions and four leaderboard metrics/icons.
- `platform/services.gd`: consent/native services and pending progress queues.

Preserve assisted versus unassisted records, atomic banked storage and explicit
Resume after fullscreen ads. Earning while an endcard is visible must not resume
simulation. Abandonment must not bank an unfinished watch or advance completed-
round interstitial cadence. Offline/Web paths must not inject rewarded grants.

## Build and test

Use matching Godot templates, JDK 17 and the configured Android SDK. Read the
commands and strict gates in `.github/workflows/build-and-deploy.yml`; run the
relevant checks for the change. Useful entry points are `tests/test_models.gd`,
`tests/test_ui.gd -- --qa-isolated`, `tests/test_ui_dispatch.gd` and
`tests/test_notice_bounds.gd`. The UI isolation flag is required by its harness.

All tests must use throwaway Godot user-data directories, including the Services
pending store, rather than genuine profiles. On Windows, run the Godot child
process with task-scoped APPDATA/LOCALAPPDATA values and restore the caller's
environment afterward. On Linux, isolate its HOME/XDG user-data/config locations.
Do not rewrite project user-directory settings or import real saves for a test.
Source tests do not substitute for native SDK/ad-return checks.

The original native-tested APK hash is recorded in `HANDOFF.txt`. Retain it when
building a new artifact; name/pin new outputs separately. CI artifacts are
separate binaries. Documentation-only changes do not require a native rebuild.
Keep local builds and raw QA outside Git, and review staged diffs for tracked QA
paths as well as untracked files; `.gitignore` does not protect tracked contents.

## Native setup

Use [PLATFORM_SETUP.md](PLATFORM_SETUP.md) for exact PGS and AdMob fields. Current
PGS mappings are blank/disabled; ads use Google sample IDs. The JSON App ID alone
does not set the Android manifest, and `test_mode` is not a test-device switch.
No production service success is established by local sample-ad QA.

## Content and notices

`python tools/build_content.py --assets-root <supplied-Kenney-pack-directory>`
reproduces selected content/art with Pillow. Existing copied assets make normal
play/build independent of that directory. Illustrations must not be presented as
actual gameplay captures. Keep original pack/license texts and engine/plugin
notices; original Apache-2.0 work does not relicense third-party content.

## Current follow-up limits

See `HANDOFF.txt` and the sanitized QA JSON for current versus historical test
scope. Physical devices, audible output, interactive Web/audio/WebGL, production
services and human balance remain unverified. UTC-clock rewards are not tamper-
proof; no saved-games backend is implemented. Owner handles real service setup,
signing, privacy/contact/consent/store declarations and Google Play publication.
Live Pages and Library actions remain outside an ordinary source update.
Future content idea: Arctic Signal, twelve ice-channel watches and harbor
cosmetics. It is a proposal, not a current implementation requirement.
