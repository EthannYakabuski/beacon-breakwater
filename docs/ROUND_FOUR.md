# Round Four: shoal navigation and remaining-ring score

The current source adds the complete Round Four rules without changing banked
save structure, equipment ownership or native service configuration. Existing
Round Three APKs and screenshots retain their original scope. New source tests
do not establish new native acceptance; exports, exact-commit CI and affected
Android checks must be recorded separately in HANDOFF.txt by the coordinator.

## Boat rules

- A boat that has never had its hull illuminated is lost immediately on a shoal,
  including crossing into one within the current simulation step. Any nonzero
  meaningful hull coverage (the existing greater-than-0.001 threshold) records
  prior illumination. Completing the inner guidance circle is not required to
  avoid this particular shoal loss. Illumination history never replaces guidance.
- All boats on a shoal move at 75% of their otherwise applicable movement speed,
  including guided, off-beam and near-harbor boats. Overlapping shoals apply the
  reduction once. Drifting/tide motion is also reduced; normal speed returns
  after leaving. Existing ring-danger/breakwater and foghorn effects remain.
- Each living arrival adds the vessel's base point value plus a remaining-ring
  bonus of `floor(base_value * clamp(life / max_life, 0, 1))`, plus the unchanged
  chain bonus. Thus keeping the outer ring healthy can add up to one extra vessel
  value. The arrival frame spends ring life before calculating this bonus. A
  life-expired ship is lost before rescue, and a removed ship cannot score twice.

The incomplete `B iii) any boat` review line supplies no additional rule.
The briefing explains the implemented shoal and score rules. No new art, ad
benefit, clock manipulation or generated progression is part of this update.

`tests/test_round_four.gd` provides 123 deterministic checks across all six boat
types: immediate/crossing losses, partial/prior/current illumination, all guided
states, overlapping shoals, outside-shoal recovery, horn combination, flare
guidance, exact ring-score fractions and once-only outcomes. Existing Round Three
tests retain their drain/geometry protections with current score expectations.
The full authored-campaign solver and scene checks remain required gates.

All source checks run with isolated temporary user-data roots. Genuine saves and
reserved Taxi state are never fixtures. Physical devices, audible output,
interactive Web, real-ID services, human balance and other previously documented
native limitations remain unverified until explicitly tested on a new binary.

Local Godot4.5.1 validation on 2026-10-24 passed 892 isolated assertions:
Round Four123, Round Three227, model235 (60/60 baseline-gear campaign watches),
Round Two38, scene66, touch dispatch113 and cold-notice bounds90. Strict logs had
no matched script/parse/assertion, resource-in-use or ObjectDB leak errors.
The first expanded briefing pushed BeginWatch beyond the initial touch viewport;
concise replacement wording restores real touch launch and the full scene suites.
The required isolated-QA argument is used by all three Beacon scene suites.
