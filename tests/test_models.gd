extends SceneTree
const Profile=preload("res://game/profile.gd")
const Watch=preload("res://game/watch.gd")
const Store=preload("res://game/save_store.gd")
var checks=0
var failures=0
func check(value: bool, label: String) -> void:
	checks+=1
	if not value: failures+=1;push_error("Assertion failed: "+label)
func _initialize() -> void: call_deferred("run_tests")
func rescue_policy(sim: RefCounted) -> void:
	# The old solver ignored returning ships because they could not expire.
	# Estimate latest safe full-light attention using ring life, remaining focus
	# and travel. Consider shared headings, not only a single boat's center.
	# Only ordinary aim/foghorn inputs are used; no model state is overridden.
	var candidates=[];var headings=[];var weights=[];var tightest=INF
	var lit_drain=Watch.GUIDED_LIT_DRAIN
	for boat in sim.boats:
		var stats=Watch.KINDS[boat.kind]
		var distance=maxf(0,boat.pos.distance_to(Watch.BEACON)-20.0)
		var life=float(boat.life)
		var danger=1.0+float(sim.config.get("storm",0))
		for reef in sim.config.get("reefs",[]):
			if boat.pos.distance_to(Vector2(reef[0],reef[1]))<reef[2]: danger*=2.5
		var focus=0.0 if boat.guided else float(stats.focus)*(1.0-float(boat.guidance))
		var min_cost=(focus*Watch.NEVER_GUIDED_DRAIN+maxf(0,distance/float(stats.lit_speed)-focus)*lit_drain)*danger
		var drain=(Watch.GUIDED_UNLIT_DRAIN if boat.guided else Watch.NEVER_GUIDED_DRAIN)*danger
		var deadline=(life-min_cost)/(drain-lit_drain*danger*float(stats.speed)/float(stats.lit_speed))
		# Reserve a short acquisition window for fresh traffic before its tighter
		# first-guidance clock forces an impossible last-second beam switch.
		if not boat.guided: deadline-=1.5
		tightest=minf(tightest,deadline)
		var weight=1.0/maxf(.1,deadline)
		if boat.guided and life>distance/float(stats.speed)*danger+.1: weight=0.0
		weights.append(weight)
		var heading=(boat.pos-Watch.BEACON).angle()
		headings.append(heading)
		candidates.append(heading)
		candidates.append(heading+sim.beam_half_width()*.5)
		candidates.append(heading-sim.beam_half_width()*.5)
	for a in range(headings.size()):
		for b in range(a+1,headings.size()): candidates.append((headings[a]+headings[b])*.5)
	var best=-1.0;var selected_heading=sim.angle
	for heading in candidates:
		sim.aim(Watch.BEACON+Vector2.from_angle(heading)*500)
		var benefit=0.0
		for index in range(sim.boats.size()):
			var coverage=sim.beam_coverage(sim.boats[index])
			if coverage>.001:
				benefit+=weights[index]*((1.0-lit_drain)+coverage*.5 if sim.boats[index].guided else coverage*1.5)
		if benefit>best: best=benefit;selected_heading=sim.angle
	if not candidates.is_empty(): sim.aim(Watch.BEACON+Vector2.from_angle(selected_heading)*500)
	# Let protection finish instead of wasting the remaining charges each frame.
	if sim.horn_effect<=.05 and sim.horn_charges>0 and tightest<1.0: sim.foghorn()

func run_tests() -> void:
	var p=Profile.new()
	check(p.data.size()==18,"eighteen banked groups")
	check(p.level()==1 and p.data.coins==140,"honest starting keeper")
	check(Profile.integer(true)==0 and Profile.integer("999")==0,"reject malformed numeric types")
	check(Profile.integer(INF)==0 and Profile.integer(-80)==0,"finite bounded normalization")
	var malformed={"version":1,"coins":-9,"xp":INF,"upgrades":{"lens":999,"focus":true},"missions":{"-1":3,"0":2,"60":3},"daily":"bad","seen":["skiff","skiff",7]}
	check(p.restore(malformed),"normalize supported schema")
	check(p.data.coins==0 and p.data.upgrades.lens==6 and p.data.upgrades.focus==0,"nested bounded wallet/equipment")
	check(p.data.missions=={"0":2} and p.data.seen==["skiff"],"bounded missions and unique typed log")
	p=Profile.new()
	var gift=p.claim_login(200)
	check(gift.coins==35 and gift.xp==12 and p.data.streak==1,"first day exact source gift")
	var after=p.data.duplicate(true)
	check(p.claim_login(200).is_empty() and p.data==after,"same day gift once")
	check(p.claim_login(199).is_empty() and p.data==after,"rollback cannot reset entitlement")
	for day in range(201,207): p.claim_login(day)
	check(p.data.streak==7,"seven sequential login days")
	check(p.claim_login(207).streak==1,"streak cycles after seventh gift")
	check(p.claim_login(220).streak==1,"missed days reset streak")
	p=Profile.new()
	check(p.upgrade_cost("lens")==70 and p.buy_upgrade("lens"),"first upgrade uses genuine wallet")
	check(p.data.coins==70 and p.data.upgrades.lens==1 and p.data.xp==0,"upgrade exact cost and no XP")
	check(p.upgrade_cost("lens")==116 and not p.buy_upgrade("lens"),"rounded escalating upgrade affordability")
	check(not p.buy_upgrade("fake") and p.data.coins==70,"unknown upgrade rejected")
	p.data.upgrades.lens=6;p.data.coins=100000
	check(not p.buy_upgrade("lens"),"equipment cap cannot be exceeded")
	p=Profile.new()
	var result={"mode":"campaign","mission":0,"rescued":4,"lost":0,"score":600,"won":true,"seen":["skiff","sailor"]}
	var paid=p.bank(result,300)
	check(paid.coins==45 and paid.xp==46 and paid.level_bonus==0,"first perfect rescue source payout")
	check(p.data.coins==185 and p.data.xp==46 and p.data.missions["0"]==3,"banked exact counters and firstclear stars")
	check(p.unlocked_mission()==1 and p.data.rescued==4 and p.data.perfect_watches==1,"sequential campaign unlock")
	paid=p.bank(result,300)
	check(paid.coins==20 and paid.xp==26 and not paid.first_clear,"replay has no duplicate firstclear")
	check(paid.level_bonus==35 and p.level()==2,"source level boundary bonus accounted separately")
	check(p.data.missions["0"]==3,"replay preserves best stars")
	p.data.daily.rescues=12
	paid=p.claim_quest("rescues")
	check(paid.coins==40 and paid.xp==20,"eligible quest exact source payout")
	after=p.data.duplicate(true)
	check(p.claim_quest("rescues").is_empty() and p.data==after,"quest repeat changes no banked group")
	p.roll_day(299);check(p.data==after,"rollback preserves daily entitlement")
	p.roll_day(301);check(p.data.daily.rescues==0 and p.data.daily_claimed.is_empty(),"forward day resets only daily work")
	var daily=result.duplicate(true);daily.mode="daily"
	check(p.bank(daily,301).daily_bonus==45 and p.bank(daily,301).daily_bonus==0,"daily watch bonus once, ordinary replay allowed")
	var spaced=Profile.new()
	for day in [100,120,140]:
		check(spaced.bank(daily,day).daily_bonus==45,"genuine new daily day%d"%day)
	check(spaced.metrics().daily_watches==3 and spaced.data.daily_best.size()==2,"spaced lifetime days survive bounded score pruning")
	var spaced_restore=Profile.new();spaced_restore.restore(spaced.data)
	check(spaced_restore.metrics().daily_watches==3,"spaced lifetime days survive typed save restore")
	check(spaced_restore.bank(daily,100).daily_bonus==0 and spaced_restore.metrics().daily_watches==3,"rollback cannot reaward a pruned historical daily")
	check(spaced_restore.bank(daily,140).daily_bonus==0 and spaced_restore.metrics().daily_watches==3,"same effective day cannot increment lifetime twice")
	var legacy=Profile.new();legacy.restore({"version":1,"daily_best":{"100":20,"120":40,"140":50}})
	check(legacy.metrics().daily_watches==3,"legacy numeric score days migrate to lifetime distinct-day counter")
	legacy.roll_day(150);var legacy_saved=legacy.data.duplicate(true)
	legacy.restore(legacy_saved);legacy.restore(legacy_saved)
	check(legacy.metrics().daily_watches==3 and legacy.data.daily_best.has("_lifetime") and not legacy.data.daily_best.has("100"),"repeated post-prune restore preserves metadata, not a numeric date")
	var endless=result.duplicate(true);endless.mode="endless";endless.won=false;endless.score=850;endless.assisted=false
	p.bank(endless,301);check(p.data.best_endless==850,"unassisted endless record")
	endless.score=5000;endless.assisted=true;p.bank(endless,301)
	check(p.data.best_endless==850,"earned assistance cannot dominate unassisted record")
	var restored=Profile.new();check(restored.restore(p.data) and restored.data==p.data,"typed complete save roundtrip")
	var path="user://beacon-model-test-%d.json"%OS.get_process_id()
	check(Store.save_progress(path,p.data),"atomic primary write")
	var original=p.data.duplicate(true);p.data.coins+=3
	check(Store.save_progress(path,p.data),"second save creates good backup")
	var corrupt=FileAccess.open(path,FileAccess.WRITE);corrupt.store_string("{broken");corrupt.close()
	var recovered=Store.load_progress(path)
	var recovered_profile=Profile.new()
	check(recovered.recovered and recovered_profile.restore(recovered.data) and recovered_profile.data==original,"checksum failure recovers genuine typed prior bank")
	for suffix in ["",".backup",".temporary"]:
		if FileAccess.file_exists(path+suffix): DirAccess.remove_absolute(path+suffix)
	var definitions=JSON.parse_string(FileAccess.get_file_as_string("res://game/missions.json"))
	check(definitions.missions.size()==60 and definitions.coasts.size()==12,"sixty explicit watches and twelve coasts")
	var ids={};var fingerprints={};var victories=0
	for definition in definitions.missions:
		ids[int(definition.id)]=true;fingerprints[JSON.stringify(definition.spawns)+JSON.stringify(definition.reefs)+str(definition.tide)]=true
		var sim=Watch.new();sim.start(definition,{"lens":0,"focus":0,"harbor":0})
		var steps=0
		while not sim.done and steps<6000:
			if steps%3==0: rescue_policy(sim)
			sim.step(1.0/30.0);steps+=1
		check(sim.done and sim.won,"baseline-gear deterministic priority solver watch%d"%definition.id)
		check(sim.rescued+sim.lost==definition.spawns.size(),"fleet conservation watch%d"%definition.id)
		check(not sim.assisted,"no ad or invulnerability in solver watch%d"%definition.id)
		if sim.won: victories+=1
	check(ids.size()==60 and fingerprints.size()==60,"unique authored IDs and traffic/coast configurations")
	var sim=Watch.new();sim.start(definitions.missions[0],{"lens":0,"focus":0,"harbor":0})
	sim.step(0);check(sim.time==0,"zero step cannot advance")
	sim.spawn("skiff",250);var boat=sim.boats[0];sim.aim(boat.pos)
	check(sim.lit(boat),"beam geometry lights target")
	var clear_width=sim.beam_half_width();sim.config.fog=.6
	check(sim.beam_half_width()<clear_width,"fog creates a real narrower beam, not only coast wording")
	sim.config.fog=0.0
	sim.angle=-.1;check(not sim.lit(boat),"beam geometry excludes far angle")
	check(sim.foghorn() and sim.horn_charges==2,"free horn consumes one charge")
	check(sim.rescue_flare() and sim.assisted and sim.boats[0].guided,"earned assistance model once")
	check(not sim.rescue_flare(),"assistance cannot be applied twice")
	var green_fleet=Watch.new();green_fleet.start(definitions.missions[0],{"lens":0,"focus":0,"harbor":0})
	green_fleet.spawn("skiff",200);green_fleet.boats[0].guided=true
	check(not green_fleet.can_flare() and not green_fleet.rescue_flare() and not green_fleet.assisted,"already-guided fleet cannot waste an earned flare")
	var snapshot=sim.result();sim.done=true;sim.step(1)
	check(sim.result()==snapshot,"finished model cannot advance behind results")
	print("BEACON MODEL CHECKS %d failures %d; baseline watches %d/60; synthetic/model only"%[checks,failures,victories])
	quit(1 if failures else 0)
