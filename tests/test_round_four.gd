extends SceneTree
## Isolated deterministic fixtures, not native gameplay or player-save evidence.
const Watch = preload("res://game/watch.gd")
var checks = 0
var failures = 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error("Assertion failed: "+label)
func world(reefs: Array = []) -> RefCounted:
	var w = Watch.new()
	w.start({"id":0,"spawns":[{"time":400,"kind":"skiff","x":50}],"duration":500,"target":99,"lives":100,"reefs":reefs},{})
	return w
func vessel(w: RefCounted, kind: String, guided: bool = false, ever: bool = false, point: Vector2 = Vector2(270,350)) -> Dictionary:
	w.spawn(kind,270)
	var b = w.boats[-1]
	b.pos = point; b.guided = guided; b.guidance = 1.0 if guided else 0.0
	b.ever_illuminated = ever
	w.angle = -.1
	return b
func count(w: RefCounted, event_name: String) -> int:
	var total = 0
	for event in w.events:
		if event.event == event_name: total += 1
	return total
func _initialize() -> void:
	for kind in Watch.KINDS:
		var w = world([[270,350,40]])
		var b = vessel(w,kind)
		w.horn_effect = 2.0; w.upgrades.breakwater = 10
		w.step(.02); w.step(.02)
		check(w.lost == 1 and w.rescued == 0 and w.score == 0 and count(w,"lost") == 1 and w.boats.is_empty(),"never-lit shoal loss is immediate and once-only despite horn/markers "+kind)
		w = world([[270,350,40]]); b = vessel(w,kind)
		w.aim(b.pos); w.step(.02)
		check(w.lost == 0 and w.boats.size() == 1 and b.ever_illuminated and not b.guided,"current partial guidance counts as having seen light "+kind)
		w.angle = -.1; w.step(.02)
		check(w.lost == 0 and b.ever_illuminated and not b.lit and not b.guided,"illumination history survives beam departure without inventing guidance "+kind)
		for guided in [false,true]:
			for lit_now in [false,true]:
				w = world([[270,350,40],[270,350,60]])
				b = vessel(w,kind,guided,true)
				if lit_now: w.aim(b.pos)
				var before: Vector2 = b.pos
				w.step(.02)
				var expected = float(Watch.KINDS[kind].lit_speed if lit_now else Watch.KINDS[kind].speed)*.75*.02
				check(absf(before.distance_to(b.pos)-expected)<.0001,"all boat states slow exactly once across overlapping shoals %s/%s/%s"%[kind,guided,lit_now])
		# Crossing the edge in a single step cannot postpone or skip the loss.
		w = world([[270,400,20]]); b = vessel(w,kind,false,false,Vector2(270,379.99))
		w.step(.05)
		check(w.lost == 1 and w.boats.is_empty(),"never-lit shoal entry resolves in the crossing step "+kind)
		w = world([[270,350,40]]); b = vessel(w,kind,false,false,Vector2(311,350))
		w.step(.02)
		check(w.lost == 0,"boat safely outside shoal is not lost "+kind)
		w = world([[270,350,40]]); b = vessel(w,kind,false,true,Vector2(270,399))
		var before: Vector2 = b.pos; w.step(.02)
		check(absf(before.distance_to(b.pos)-float(Watch.KINDS[kind].speed)*.02)<.0001,"normal speed returns beyond shoal "+kind)
		# Score follows actual remaining outer ring, after this arrival frame's drain.
		var previous_score = -1
		for fraction in [.1,.5,.9]:
			w = world(); b = vessel(w,kind,true,true,Watch.BEACON+Vector2(0,-15))
			b.max_life = 1000.0; b.life = 1000.0*fraction; w.aim(b.pos)
			w.step(.01)
			var expected = int(Watch.KINDS[kind].value)+int(floor(float(Watch.KINDS[kind].value)*float(b.life)/1000.0))+10
			check(w.rescued == 1 and w.score == expected and count(w,"rescue") == 1,"arrival uses exact remaining-ring bonus %s/%.1f"%[kind,fraction])
			check(w.score > previous_score,"more remaining ring awards more rescue points %s/%.1f"%[kind,fraction])
			previous_score = w.score
			var banked = w.score; w.step(.05)
			check(w.score == banked and count(w,"rescue") == 1,"removed boat cannot score twice %s/%.1f"%[kind,fraction])
		w = world(); b = vessel(w,kind,true,true,Watch.BEACON+Vector2(0,-15)); b.life = .0001
		w.step(.02)
		check(w.lost == 1 and w.score == 0,"expired ring cannot award score on arrival "+kind)
	# Foghorn and shoal modifiers combine without repeatedly compounding.
	var w = world([[270,350,60],[270,350,40]])
	var b = vessel(w,"skiff",false,true); b.drift = 12; w.horn_effect = 1
	var before: Vector2 = b.pos; w.step(.02)
	check(absf(b.pos.x-before.x-12*.75*.25*.02)<.0001 and absf(b.pos.y-before.y-28*.75*.25*.02)<.0001,"shoal scales whole drift motion once alongside existing horn")
	w = world([[270,350,40]]); b = vessel(w,"skiff")
	check(w.rescue_flare(),"real earned model assistance can establish guidance")
	w.step(.02)
	check(w.lost == 0 and b.ever_illuminated and b.guided,"earned flare establishes safe guidance but does not bypass slowdown")
	print("BEACON ROUND FOUR CHECKS %d failures %d; deterministic source only"%[checks,failures])
	quit(1 if failures else 0)
