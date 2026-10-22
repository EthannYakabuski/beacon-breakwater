extends SceneTree
## Deterministic source fixtures only; never native progression/capture evidence.
const Watch=preload("res://game/watch.gd")
var checks=0
var failures=0
func check(value: bool,label: String) -> void:
	checks+=1
	if not value: failures+=1;push_error("Assertion failed: "+label)
func close_motion(actual: float,expected: float) -> bool:
	# Vector2 positions use float32: subtracting world coordinates near y=690
	# loses a few 1e-5 pixels. Bound that quantization below 0.0001 pixels.
	return absf(actual-expected)<.0001
func world(levels: Dictionary={},extra: Dictionary={}) -> RefCounted:
	var definition={"id":0,"spawns":[],"duration":500,"target":1,"lives":100}
	definition.merge(extra,true)
	var watch=Watch.new();watch.start(definition,levels)
	return watch
func vessel(w: RefCounted,kind: String,guided: bool,illuminated: bool,point: Vector2=Vector2(270,350)) -> Dictionary:
	w.spawn(kind,270)
	var boat=w.boats[-1];boat.pos=point;boat.guided=guided
	boat.guidance=1.0 if guided else 0.0
	if illuminated: w.aim(point)
	else: w.angle=-.1
	return boat
func event_count(w: RefCounted,key: String) -> int:
	var total=0
	for event in w.events:
		if event.event==key: total+=1
	return total
func _initialize() -> void:
	for kind in Watch.KINDS:
		for phase in ["never_dark","never_lit","return_dark","return_lit"]:
			var guided=phase.begins_with("return")
			var illuminated=phase.ends_with("lit")
			var w=world();var boat=vessel(w,kind,guided,illuminated)
			var before=float(boat.life);var position: Vector2=boat.pos
			w.step(.02)
			var rate=1.33 if not guided else .3125 if illuminated else 1.0
			check(is_equal_approx(before-float(boat.life),.02*rate),"actual ring drain %s %s"%[kind,phase])
			check(w.ring_phase(boat)==("never_guided" if not guided else "guided_lit" if illuminated else "guided_unlit"),"ring phase %s %s"%[kind,phase])
			var speed=float(Watch.KINDS[kind].lit_speed if illuminated else Watch.KINDS[kind].speed)
			check(close_motion(position.distance_to(boat.pos),speed*.02),"coverage speed preserved %s %s"%[kind,phase])
			check(event_count(w,"guided")==0 and w.rescued==0 and w.lost==0,"no false guidance or accounting %s %s"%[kind,phase])
		# First acquisition spends ring life on the completion frame, then keeps
		# routing without staying green or emitting guidance again off the beam.
		var w=world();var boat=vessel(w,kind,false,true);boat.guidance=.99999
		var before=float(boat.life);w.step(.02)
		check(boat.guided and event_count(w,"guided")==1 and is_equal_approx(before-float(boat.life),.00625),"first completed circle drains without skipped frame "+kind)
		w.angle=-.1;before=float(boat.life);var prior_distance=boat.pos.distance_to(Watch.BEACON);w.step(.02)
		check(boat.guided and not boat.lit and w.ring_phase(boat)=="guided_unlit" and boat.pos.distance_to(Watch.BEACON)<prior_distance,"off-beam completed circle retains route, not lit phase "+kind)
		check(is_equal_approx(before-float(boat.life),.02) and event_count(w,"guided")==1,"off-beam drain and once-only completion "+kind)
		# Each phase retains storm, reef, breakwater and free horn protection.
		for phase in ["never","dark","lit"]:
			w=world({"breakwater":3},{"storm":.4,"reefs":[[270,350,120]]});w.time=10.5;w.horn_effect=1.0
			boat=vessel(w,kind,phase!="never",phase=="lit");before=float(boat.life);w.step(.02)
			var rate=1.33 if phase=="never" else .3125 if phase=="lit" else 1.0
			var expected=.02*1.4*(1.0+1.5/1.6)*.25*rate
			check(is_equal_approx(before-float(boat.life),expected),"weather/reef/horn combine in every ring phase %s %s"%[kind,phase])
		# Hull+arrival geometry: 48 logical pixels, inclusive. Only a completed
		# circle earns this speed exception; the actual off-beam state stays true.
		for distance in [47.9,48.0,48.1]:
			w=world();boat=vessel(w,kind,true,false,Watch.BEACON+Vector2(0,-distance))
			before=float(boat.life);var position: Vector2=boat.pos;w.step(.01)
			var expected_speed=float(Watch.KINDS[kind].lit_speed if distance<=48.0 else Watch.KINDS[kind].speed)
			check(close_motion(position.distance_to(boat.pos),expected_speed*.01),"actual near-shore speed boundary %s %.1f"%[kind,distance])
			check(not boat.lit and boat.coverage==0 and w.ring_phase(boat)=="guided_unlit" and is_equal_approx(before-float(boat.life),.01),"near-shore exception grants speed only %s %.1f"%[kind,distance])
			check(event_count(w,"guided")==0 and w.rescued==0 and w.score==0,"near-shore exception creates no guidance/reward %s %.1f"%[kind,distance])
		w=world();boat=vessel(w,kind,false,false,Watch.BEACON+Vector2(0,-40))
		check(not w.near_shore_guidance(boat) and w.travel_speed(boat,0)==Watch.KINDS[kind].speed,"unguided near-shore ship gets no speed exception "+kind)
		w=world();boat=vessel(w,kind,true,true,Watch.BEACON+Vector2(0,-45))
		var near_coverage=w.beam_coverage(boat);var near_position: Vector2=boat.pos;before=float(boat.life);w.step(.01)
		check(near_coverage>0 and near_coverage<1 and boat.lit,"near-shore partial hull retains truthful illumination "+kind)
		check(close_motion(near_position.distance_to(boat.pos),Watch.KINDS[kind].lit_speed*.01),"near-shore partial hull still receives full return speed "+kind)
		check(is_equal_approx(before-float(boat.life),.003125) and event_count(w,"guided")==0,"near-shore partial hull spends illuminated ring life without another guidance event "+kind)
		# Life reaches zero before harbor rescue: neither a second loss nor a
		# reward can emerge when this finished model receives more frames.
		w=world();boat=vessel(w,kind,true,false,Watch.BEACON+Vector2(0,-15));boat.life=.001
		w.step(.05);var result=w.result();w.step(.05)
		check(w.lost==1 and w.rescued==0 and w.score==0 and w.boats.is_empty() and w.lost_boats.size()==1 and event_count(w,"lost")==1 and w.result()==result,"expired guided ship loses exactly once before harbor rescue "+kind)
		w=world();boat=vessel(w,kind,true,true,Watch.BEACON+Vector2(0,-15));w.step(.01);result=w.result();w.step(.05)
		check(w.rescued==1 and w.lost==0 and w.score==Watch.KINDS[kind].value+10 and w.boats.is_empty() and event_count(w,"rescue")==1 and w.result()==result,"living harbor arrival scores exactly once "+kind)
	# Partial hull coverage still increases acquisition and speed gradually.
	var w=world();var boat=vessel(w,"skiff",false,true)
	w.angle=(boat.pos-Watch.BEACON).angle()+w.beam_half_width()
	var coverage=w.beam_coverage(boat);var before: Vector2=boat.pos;w.step(.02)
	check(coverage>.25 and coverage<.75 and is_equal_approx(float(boat.guidance),.02/1.05*coverage),"partial hull gradually acquires first guidance")
	check(close_motion(before.distance_to(boat.pos),lerpf(28,52,coverage)*.02),"actual partial hull speed remains proportional")
	# Tide/horn movement and focus upgrades remain separate from ring phases.
	w=world({"focus":4},{"tide":9});boat=vessel(w,"cargo",false,true);w.horn_effect=1.0;before=boat.pos;w.step(.02)
	check(is_equal_approx(float(boat.guidance),.02*1.52/2.25) and close_motion(boat.pos.x-before.x,9*.02*.25),"focus and horn-slowed tide remain effective")
	# Earned model assistance can route a fleet once, but does not exempt its
	# rings; UI tests separately cover fullscreen/explicit Resume and banking.
	w=world();boat=vessel(w,"barge",false,false);check(w.rescue_flare(),"useful fleet can accept one flare")
	var life=float(boat.life);w.step(.02)
	check(boat.guided and not boat.lit and is_equal_approx(life-float(boat.life),.005) and not w.rescue_flare(),"flare retains horn protection without guided immunity or duplicate grant")
	print("BEACON ROUND THREE CHECKS %d failures %d; deterministic source only"%[checks,failures])
	quit(1 if failures else 0)
