# Round Three: ring phases and harbor approach

`game/watch.gd` keeps completed guidance (`guided`) separate from current rendered
hull illumination (`lit` and `coverage`). A completed circle still routes a ship
home. Moving the beam away changes its outer ring back to gold, or coral when its
remaining budget is below 35%; it no longer stays green or gains immunity.

All six ship types keep their Round Two ring budgets, focus, normal/full-light
speeds and point values. Each active frame now spends that ring budget as follows,
before the existing storm, reef/breakwater and foghorn multipliers:

| State | Ring units spent per second |
| --- | ---: |
| Guidance circle never completed, even if partly illuminated | 1.33 |
| Circle completed earlier, currently off beam | 1.0 |
| Circle completed, currently illuminated | 0.3125 |

The first value is the old unlit drain increased by 33%. The second retains the
old unlit rate. Round Two's guided branch skipped ring drain entirely, so there
was no nonzero illuminated rate to increase by 25%. The explicit design assumption
is a slow baseline of one quarter of the old unlit rate, then the requested 25%
increase: `0.25 * 1.25 = 0.3125`. This is a new baseline, not a percentage increase
of the previous zero drain. Initial guidance acquisition still depends on focus
and actual covered hull area; completing it emits one event and does not skip the
current frame's life/movement updates.

Away from shore, speed still interpolates with actual hull coverage. A previously
guided ship within 48 logical pixels of the beacon keeps its full-light speed
when its hull clips the cone apex. The threshold is the 28-pixel half-length of
the rendered hull plus the existing 20-pixel arrival radius. This exception only
affects speed: current coverage, ring color and decay remain truthful, and no
guidance event, immunity, rescue or score is manufactured. Life expiration is
resolved before rescue; each removed vessel can contribute only one outcome.

No banked save schema, owned upgrade, production service ID, ad entitlement or
explicit Resume behavior changes. The foghorn/flare protection and existing
assisted-record rules still apply. `tests/test_round_three.gd` checks the actual
step behavior for all six types, first guidance, beam exit, drain modifiers,
near-shore boundaries, losses and once-only rescues. Scene tests cover ring colors
and pause/endcard lifecycle. The 60 authored campaign watches must still pass the
ordinary, unassisted baseline-gear solver with fleet conservation enforced.

Source test results are not native gameplay acceptance. The existing `HANDOFF.txt`
identifies the historical native-tested Round Two APK and captures. The separately named Android/Web exports below are now verified. Affected
native checks and fresh capture provenance are still required before a Round Three
package is described as natively accepted.

## Source validation, 2026-10-22

Matching Godot 4.5.1 headless import and isolated service smoke checks passed.
The six game suites passed 769 assertions: model/accounting/save 235 (all 60
baseline-gear campaign watches won with fleet conservation and no assistance),
Round Three 227, Round Two 38, scene/lifecycle 66, touch dispatch 113 and cold
notice bounds 90. Strict logs contained no script/parse/errors or failed assertions.

The campaign test's former policy stopped attending to any ship after guidance
completed. Its replacement uses ordinary beam aiming and the free foghorn only,
including shared headings for nearby hulls and protection-aware horn timing.
No life, elapsed time, mission content, upgrade, win condition or conservation
assertion was changed to obtain these results. Automated solvability does not
establish human balance, physical-device performance or native ad acceptance.

## Verified exports and exact-source CI, 2026-10-22

Runtime/source commit: `b71583c14a7fbaddb05f6faed5bd24cda970f8de`.

- Android: `build/round-three-b71583c1-a1/android/beacon-breakwater-debug.apk`; 194578744 bytes.
  SHA256 `02EEFCE690AFD59F1A1614C91AEE97C05636F1951FF3AE96FE1BFFB3B9703C8F`.
- Web: `build/round-three-b71583c1-a1/web/index.html` plus every sidecar and notice.
- [Exact-runtime hosted build/test CI](https://github.com/EthannYakabuski/beacon-breakwater/actions/runs/39795036517): **SUCCESS**, with the same runtime commit.

Both exports passed source/input binding, strict error checks and complete-notice verification. They were compiled from frozen committed export settings; unrelated owner working-tree files/settings remain preserved and were not build inputs. These are export-only candidates, distinct from hosted artifacts and historical native-tested binaries. Later documentation commits require their own CI result.

**Native acceptance remains pending.** This Round Three APK has not yet received native testing. Native work is delayed by task-emulator System UI failure; no application defect is inferred and no Round Three screenshots are accepted. Affected native behavior and six genuine screenshots per phone/7-inch/10-inch profile are still required. See `../HANDOFF.txt` for complete artifact identities and dated Round Two qualifications. Interactive Web, audible output, physical devices and production backend/services remain unverified.
