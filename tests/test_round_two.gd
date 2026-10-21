extends SceneTree
## Synthetic deterministic regressions; not native gameplay/capture evidence.
const Watch=preload("res://game/watch.gd")
const Profile=preload("res://game/profile.gd")
var checks=0
var failures=0
func check(value: bool,label: String) -> void:
	checks+=1
	if not value: failures+=1;push_error("Assertion failed: "+label)
func _initialize() -> void:
	var definition={"id":0,"spawns":[],"duration":500,"target":1,"lives":3}
	var w=Watch.new();w.start(definition,{})
	w.spawn("skiff",270)
	var boat=w.boats[0];w.aim(boat.pos)
	check(w.beam_coverage(boat)>.99,"full rendered-footprint coverage")
	w.angle=(boat.pos-Watch.BEACON).angle()+w.beam_half_width()
	var partial=w.beam_coverage(boat)
	check(partial>.25 and partial<.75,"beam-edge partial footprint coverage")
	w.angle=-.1
	check(w.beam_coverage(boat)==0.0,"off-beam footprint has zero coverage")
	for key in Watch.KINDS:
		var stats=Watch.KINDS[key]
		check(stats.lit_speed<=59.0 and stats.lit_speed>stats.speed,"at least half old guided speed and real boost "+key)
		var ship={"kind":key}
		check(w.travel_speed(ship,0)==stats.speed and w.travel_speed(ship,1)==stats.lit_speed,"off-beam resets base speed "+key)
		check(is_equal_approx(w.travel_speed(ship,.5),(stats.speed+stats.lit_speed)*.5),"proportional half illumination "+key)
	var old_life={"skiff":17.0,"sailor":21.0,"cargo":25.0,"rescue":13.0,"cutter":15.0,"barge":29.0}
	for key in old_life: check(is_equal_approx(Watch.KINDS[key].life,old_life[key]*.75),"ring budget reduced25percent "+key)
	w.start(definition,{})
	w.spawn("skiff",270);boat=w.boats[0];boat.guided=true
	w.angle=-.1;var before: Vector2=boat.pos;w.step(.02)
	check(is_equal_approx(before.distance_to(boat.pos),Watch.KINDS.skiff.speed*.02),"guided off-beam boat returns to original pace in actual step")
	w.start(definition,{})
	for index in range(3): w.spawn("rescue",100+index*100);w.boats[index].life=.001
	w.step(.05)
	check(w.done and not w.won and w.lost==3 and w.can_continue(),"natural three-loss result offers second chance")
	check(w.continue_watch() and w.continued and w.assisted and not w.done and w.lost==0 and w.boats.size()==3,"earned continuation recovers actual lost fleet and preserves same watch")
	check(not w.continue_watch(),"continue cannot apply twice")
	var p=Profile.new();var legacy=p.data.duplicate(true)
	legacy.upgrades={"lens":4,"focus":2,"harbor":1};legacy.missions={"0":3,"29":2};legacy.coins=900;legacy.xp=400
	var migrated=Profile.new();check(migrated.restore(legacy),"legacy version1 loads")
	check(migrated.data.coins==900 and migrated.data.xp==400 and migrated.data.upgrades.lens==4 and migrated.data.upgrades.horn==0 and migrated.data.upgrades.breakwater==0,"legacy bank/owned upgrades preserved while adding new defaults")
	migrated.data.missions={}
	for id in range(60): migrated.data.missions[str(id)]=3
	check(migrated.unlocked_mission()==59 and migrated.metrics().coasts==12,"all60levels and12packs persist/unlock")
	var restored=Profile.new();check(restored.restore(migrated.data) and restored.data==migrated.data,"expanded profile roundtrip")
	p=Profile.new();var paid=p.bank({"won":true,"lost":0,"rescued":4,"mode":"campaign","continued":true,"assisted":true},10)
	check(not paid.perfect and paid.stars==2 and p.data.perfect_watches==0,"continued result cannot manufacture perfect record")
	w.start(definition,{"horn":6,"breakwater":6})
	check(w.max_horn_charges()==6 and w.horn_duration()>3.3,"new horn upgrade has distinct gameplay effects")
	var scores=[];var speeds=[];var rings=[]
	for stats in Watch.KINDS.values():scores.append(stats.value);speeds.append(stats.speed);rings.append(stats.life)
	check(scores.size()==6 and scores.count(70)==1 and speeds.min()==13.0 and speeds.max()==42.0 and rings.min()==9.75,"distinct vessel stat spread")
	print("BEACON ROUND TWO CHECKS %d failures %d; synthetic model only"%[checks,failures])
	quit(1 if failures else 0)
