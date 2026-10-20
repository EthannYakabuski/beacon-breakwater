# Developer configuration

Godot4.5.1 Compatibility, portrait540x960 logical stage with fitted letterboxing.
Android is primary. Web uses single-threaded rendering and graceful native-service
fallbacks. Do not activate a Windows export or self-hosted CI runner.

`game/watch.gd` is deterministic simulation, independent of storage, wall-clock
time, UI and services. `game/profile.gd` owns all banked accounting, typed bounded
normalization, equipment costs, level bonuses and monotonic UTC-day rewards.
`game/save_store.gd` owns checksummed atomic saves and backup recovery.
`game/main.gd` connects ordinary touch UI, lifecycle pause, once-only result
banking and stale-generation-safe native callbacks. `game/missions.json` contains
30 curated compositions of explicitly authored traffic phrases, six coast
hazard/weather configurations and explicit rescue/priority goals. They are not
represented as thirty random seeds or as human-balanced difficulty proof.

## IDs and native setup

`platform/config.json` uses Google's official Android test app ID ending3347511713
and banner6300978111/interstitial1033173712/rewarded5224354917. Keep test mode on
for development. Real IDs, consent configuration, target audience and appropriate
disclosures are owner-controlled. Web must never grant a simulated native reward.

Play Games starts disabled. Supply the numeric game ID and every symbolic
achievement/leaderboard mapping from `game/catalog.json`, then enable it only
after OAuth/app/signing setup. Also set `godot_play_game_services/game_id` in the
Android preset. Production signing keys are never committed. The repository has
no service-account file or backend credential. Enable saved-games backend only
as an explicit extension; the implemented offline harbor save is authoritative.

The Services adapter queues achievements/scores locally while unavailable and
uses the current audited fullscreen/earned callback lifecycle. Interstitials
occur after every two naturally completed watches. Abandonment does not advance
cadence or bank an unfinished watch. Reward context is `one breakwater rescue
flare`; a granted callback can guide visible boats but screen remains paused.
Never make earning itself resume simulation, hide the endcard or inject a grant.

## Content/art reproduction

```
python tools/build_content.py --assets-root <supplied-Kenney-pack-directory>
```

This requires Pillow in the local development environment. Existing copied assets
make normal build/play independent of that directory. The script records relative
pack source paths and exact selected bytes. Store art is code-drawn illustration;
it must not be presented as real gameplay capture. Preserve original pack license
text and all engine/plugin notices. Canonical source edits, exports, real Android
captures and publication are coordinated separately from this staging work.

## Limits and extension

Local UTC clock rewards are not tamper-proof. No production backend, physical
device, audible Android output, full human balancing or long-session guarantee is
inferred from model tests. Android min24/target35 follows Godot4.5.1's actual export
constraint; owner must check current release requirements. Future DLC proposal:
Arctic Signal, twelve ice-channel watches and aurora harbor cosmetics. Base game
remains complete without DLC or purchases.
