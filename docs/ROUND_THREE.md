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

Source test results are separate from native gameplay acceptance. `HANDOFF.txt`
now identifies the current Round Three export and qualified native scope, plus
the preserved Round Two APK and captures. Eighteen fresh current-build screenshots
are independently accepted; remaining native limits are explicit below.

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

Both exports passed source/input binding, strict error checks and complete-notice verification. They were compiled from frozen committed export settings; unrelated owner working-tree files/settings remain preserved and were not build inputs. These local test exports are distinct from hosted artifacts and historical native-tested binaries. The current qualified native scope is below; later documentation/capture commits require their own CI result.

## Qualified native scope and screenshots, 2026-10-22

Limited affected native checks and 18 fresh raw screenshots are complete on the exact 02EE APK. Ordinary aiming showed never-completed guidance, completed currently-lit teal rings and completed off-beam coral rings with routing retained. Free foghorn worked. One guided boat reached home without further reaiming at the cone apex. This observation does not measure numeric ring drain, exact speed or the fully uncovered near-shore exception.

Android Back/pause, background return, a genuine failed2 HOME / 2 LOST outcome and source-defined 6 coins / 8 XP once-only bank were observed. Cold loaded Home retained banked main bytes without another restoration. A tablet capture-watch was explicitly abandoned without banking unfinished progress. The profile was initially restored from a genuine historical backup after a temporary host-session loss; restoration is not retention across that loss.

The [capture manifest](../marketing/screenshots-round-three/capture-manifest.json) records six actual screenshots per phone/logical 7-inch/logical 10-inch profile, with exact hashes/dimensions/densities. Operator and coordinator reviewed every unchanged PNG. Important controls fit; long lists intentionally scroll. Logical profiles do not prove physical-tablet acceptance.

Actual disconnected networking remains unverified because guest flags/UI did not remove validated connectivity. Current fullscreen ad display/return was not exercised; unused optional ad buttons do not imply absence of SDK initialization/prefetch. Native numeric drain/speed measurements, human balance, audible output, physical devices, interactive Web and production services remain unverified. The bounded recent-log scan found no targeted matches, without an exhaustive SDK-clean claim. See `../HANDOFF.txt` and `NATIVE_QA.json` for exact current and historical scopes.
