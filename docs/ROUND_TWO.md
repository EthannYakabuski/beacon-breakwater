# Round Two: a wider coast

## Rescue behavior and accounting

`watch.gd` measures the portion of the rotated 36x56 boat sprite footprint inside
the beam triangle. Coverage proportionally controls guidance gain and movement;
it uses the rectangular sprite footprint, including transparent margins, rather
than an alpha-mask collision. Every boat immediately returns to its type's base
speed off beam, including boats already guided. Base/lit speeds are skiff28/52,
sailor24/43, cargo17/34, rescue34/55, cutter42/58 and barge13/27. All lit caps are
at least50% below the former118. Vessel points and ring budgets differ by type;
ring budgets are exactly75% of the former values. Unlit travel still takes time.

A naturally lost watch with recoverable traffic can offer one earned rewarded
continue. The actual lost fleet returns, remaining rings/deadline are refreshed,
and the watch becomes assisted. It stays on Pause after the earned callback;
fullscreen dismissal and explicit Resume remain required. No callback banks a
result. Leaving a pending loss banks it once; a continued result banks only its
final outcome. Continued wins cannot earn a perfect record or three stars.
Per-request serials reject stale and duplicate reward callbacks. Web, unavailable
ads and unearned dismissal never fabricate rewards.

Save schema1 and its eighteen banked top-level groups remain. Existing mission
IDs0..29, coins, XP, purchases, records and claims are retained. New mission IDs
30..59 add six five-watch East Coast groups. New horn/breakwater upgrades default
to0; lens/focus/harbor purchases remain exact. Five upgrade families cap at6.
Active watches remain intentionally nonresumable across process death.

## Content, art and audio

There are60 curated watches in12 coasts, plus Endless and Daily. Kenney UI Pack filled textures and a true hollow CC0 vector derivative show
ratings, with the original outline source retained. `game/catalog.json` defines26 achievement
keys (existing20 plus coast7..coast12) and four boards; owner IDs already supplied
to old keys must be preserved when extending mappings. Illustrated harbor,
lighthouse and shoal originals/provenance are in `assets/art`; the lantern aligns
with the beam origin and the shoal's3:2 footprint preserves its aspect ratio.

`tools/build_content.py --music` composes thirteen original16-bar WAV scores:
menu plus one per coast, with different key/progression/lead arrangements and
second-half variation. Loops last approximately36..46seconds with harmonic pad,
bass and melody. Music/effects settings work independently, and application/
fullscreen pause suspends playback. Guidance, arrivals, horn, upgrades and
assistance have separate licensed feedback. Source and license manifests retain
Kenney CC0 notices and original score provenance.

New illustrated app/feature images are packaged from retained originals using
standard resizing. All26achievement and four leaderboard illustrations are replaced and packaged
at512px; final-size pages and64px thumbnails were inspected. The old screenshot set is historical until final-build
phone/logical7/logical10 captures replace it. Illustrations are not screenshots.

## Verification and remaining acceptance

Godot4.5.1 Compatibility clean import and strict isolated checks passed: new38,
model235, UI57, dispatch106, bounds90 and service smoke. The deterministic priority
solver completed all60 missions with baseline gear and no ad benefit. Synthetic
fixtures verify proportional/off-beam movement, legacy roundtrips, once-only
banking, earned/unearned/duplicate callbacks and explicit Resume. These fixtures
are not actual native rewards or balance acceptance from a human player.

A private Windows Compatibility GPU run passed52 actual-player/render checks:
all twelve pack tracks, menu selection,36..46second loop resources, settings,
pause/background state and actual rendered phone/logical-tablet pages. Five
views were inspected. Its process audio bus was muted; no audible quality or
Android audio claim follows from that test.

The original APK/hash and earlier native QA remain in `HANDOFF.txt`. They were not
rebuilt or re-tested by these source checks. New Android/Web exports, affected
native gameplay/earned-continue/endcard/Back/save/offline checks, final-build
captures are required before the updated package's
handoff. Hosted CI validates its exact commit and is distinct from original local
APK QA. Physical devices, production services, audible output, interactive Web,
long sessions and human balance acceptance remain unverified.


## Native-discovered card scrolling correction

Card PanelContainers now pass GUI events to their ScrollContainer; child action
Button filters and ownership are unchanged. The earlier source let a touch drag
over a card body stop at the panel, leaving a clipped Begin control inaccessible
without using the narrow scrollbar. An isolated actual Viewport reproduction
showed zero scroll before this one-property correction and full available scroll
after it. A measured-reserve fixture now proves the Begin button is clipped,
drags through the card body to reveal it, and activates it exactly once with the
ordinary paired touch/mouse release. Dragging preserves the page and banked data.

Focused strict checks passed:113 paired-touch dispatch,106 mouse dispatch,57
fullscreen/UI and90 notice-bounds checks, with no engine errors. Test touchscreen
emulation is confined to the fixture process; project/platform settings and real
saves are unchanged. New exports and affected native controls must be verified;
the preceding c0bd98f build's observations do not certify this corrected binary.
