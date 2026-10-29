# Round Five: clear choices and a calmer endless opening

## Player-facing changes

The active watch HUD shows three boat icons under **CHANCES**. Each lost vessel
spends one icon: the slot dims and gains a coral cross. The tooltip states the
remaining allowance, and the watch still ends on its third loss. The HUD keeps
rescued boats, elapsed time, points and chain information. No save or scoring
rule changes accompany this display.

Campaign **Start watch** cards launch the selected watch directly. Their cards
keep the rescue target and any required ship type/count visible before launch.
Daily and next-watch actions also start directly; the old briefing entry point
is only a compatibility redirect. Pause/help, fullscreen-ad pause protection,
ordinary replay and once-only banking remain available.

Endless starts from a calm Lantern Bay presentation, independently of late
campaign mission hazards. It opens with one shoal and basic fishing skiffs.

| Elapsed time | Available hulls | Maximum shoals |
| --- | --- | --- |
| 0–59 seconds | Skiff | 1 |
| 60–119 seconds | Skiff, sailor | 2 |
| 120–179 seconds | Add cargo freighter | 3 |
| 180–239 seconds | Add emergency launch | 4 |
| 240–299 seconds | Add fast cutter | 4 |
| 300 seconds onward | Add heavy barge | 4 |

Spawn spacing falls gradually from seven seconds to four over the first three
minutes, then toward a two-second minimum. Tide, fog, storms and lateral drift
are absent in the first minute and build gradually afterward. Later shoals use
fixed landmarks. A shoal waits while an existing hull overlaps its radius plus
42 logical units of clearance; it cannot pop underneath that vessel. Earlier
shoals do not move. A continued watch keeps elapsed difficulty rather than
restarting the easy opening.

## Acceptance and verification

- A: `tests/test_ui.gd` checks three rendered boat slots, remaining/spent states,
  descriptive tooltip, bounds and continued access to ordinary controls.
- B: UI and real Viewport event-dispatch tests require a single mission-card
  activation to reach play without a second Begin screen. Mission-list drag
  scrolling still has a distinct non-activating test.
- C: `tests/test_round_five.gd` exercises real first-minute spawning, staged hulls,
  bounded monotonic traffic/weather, shoal clearance/defer behavior, continued
  difficulty and preservation of all 60 campaign configurations.

Run the current tests under fresh process-scoped Godot user-data directories;
UI/dispatch fixtures also require `--qa-isolated`. Preserve the strict engine,
parse, script and assertion error checks. These are source/engine fixtures, not
evidence of native Android rendering, audible output, human balance or real ads.

Local Godot4.5.1 import and all nine scoped scripts passed with strict clean
diagnostics:111 Round Five,83 UI,105 dispatch,235 baseline (60/60 campaign
watches),38 Round Two,227 Round Three,123 Round Four,90 notice and service
smoke. These are isolated source/engine checks. Current results and the exact
source/build qualification are recorded in `HANDOFF.txt`. Match hosted CI to the containing commit. Existing APK/AAB files,
screenshots and older handoffs retain their original build provenance and do not
contain these changes. The owner's untracked feature artwork and configuration
remain separate from this source update.
