extends SceneTree
## Deterministic model fixtures only; no native gameplay or real player saves.
const Watch=preload("res://game/watch.gd")
var checks=0
var failures=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures+=1;push_error("Assertion failed: "+label)
func _initialize() -> void:
	var missions: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://game/missions.json"))
	var original: Dictionary=missions.missions[55].duplicate(true)
	var w=Watch.new();w.start(original,{},"endless")
	check(w.config.reefs.size()==1 and w.config.fog==0.0 and w.config.tide==0.0 and w.config.storm==0.0,"late campaign template cannot leak its hazards/weather into the endless opening")
	check(original==missions.missions[55],"endless setup does not mutate authored mission data")
	check(w.endless_kinds()==["skiff"] and is_equal_approx(w.endless_interval(),7.0),"endless opens with one basic vessel type and seven-second spacing")
	# Run the real first-minute spawn loop. Large fixture life allowance lets this
	# inspect arrivals independently of this test's deliberately absent aim input.
	w.config.lives=1000
	for tick in range(1199): w.step(.05)
	check(w.time>59.9 and w.time<60.0 and w.seen==["skiff"],"actual first minute never spawns an advanced hull")
	check(w.serial>=8 and w.serial<=10 and w.config.reefs.size()==1,"opening has slower real arrival cadence and one shoal for the full minute")
	var previous_interval=100.0
	for elapsed in [0.0,59.9,60.0,119.9,120.0,180.0,240.0,300.0,480.0,900.0]:
		w=Watch.new();w.start(original,{},"endless");w.time=elapsed;w._update_endless_progression()
		var expected=mini(6,1+int(elapsed/60.0))
		check(w.endless_kinds().size()==expected,"one new vessel type per minute %.1f"%elapsed)
		check(w.config.reefs.size()==mini(4,1+int(elapsed/60.0)),"shoal count builds to a bounded four %.1f"%elapsed)
		check(w.endless_interval()<=previous_interval and w.endless_interval()>=2.0,"traffic cadence tightens continuously without falling below two seconds %.1f"%elapsed)
		previous_interval=w.endless_interval()
		check(w.config.fog>=0.0 and w.config.fog<=.300001 and w.config.storm>=0.0 and w.config.storm<=.300001,"weather stays bounded %.1f"%elapsed)
	# A new shoal must wait instead of appearing underneath a current hull.
	w=Watch.new();w.start(original,{},"endless");w.time=60.0;w.spawn("skiff",430)
	w.boats[0].pos=Vector2(430,475)
	w._update_endless_progression()
	check(w.config.reefs.size()==1,"new shoal is deferred under an existing vessel")
	w.boats[0].pos=Vector2(430,410);w._update_endless_progression()
	check(w.config.reefs.size()==1,"new shoal also protects full hull plus warning clearance")
	w.boats[0].pos=Vector2(270,175);w._update_endless_progression()
	check(w.config.reefs.size()==2,"deferred shoal appears when water becomes clear")
	var first_shoal: Array=w.config.reefs[0].duplicate()
	w.time=180.0;w._update_endless_progression()
	check(w.config.reefs.size()==4 and w.config.reefs[0]==first_shoal,"progress adds landmarks rather than moving earlier shoals")
	# A real continuation retains elapsed difficulty rather than restarting easy.
	w.time=240.0;w.done=true;w.won=false;w.lost_boats=[{"kind":"skiff","x":200.0,"drift":0.0}]
	check(w.continue_watch(),"continuation remains available to a lost endless watch")
	w._update_endless_progression()
	check(w.time==240.0 and w.endless_kinds().size()==5 and w.config.reefs.size()==4,"continuation never resets difficulty milestones")
	# All sixty campaign definitions retain their existing rules and geography.
	for definition in missions.missions:
		w=Watch.new();w.start(definition,{},"campaign")
		var before=w.config.duplicate(true);w._update_endless_progression()
		check(w.config==before and w.config==definition,"campaign remains unchanged watch%d"%int(definition.id))
	print("BEACON ROUND FIVE CHECKS %d failures %d; source simulation only"%[checks,failures])
	quit(1 if failures else 0)
