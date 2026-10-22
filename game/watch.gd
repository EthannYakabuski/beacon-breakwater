extends RefCounted
## Deterministic 2D rescue simulation. Native/clock/UI/storage independent.
# Base ring budgets are 25% below Round One. Full-beam speed never exceeds
# 58 units/s, versus the old unconditional 118 units/s guided speed.
const KINDS = {
	"skiff":{"label":"Fishing skiff","focus":1.05,"life":12.75,"speed":28.0,"lit_speed":52.0,"value":70},
	"sailor":{"label":"Coastal sailer","focus":1.5,"life":15.75,"speed":24.0,"lit_speed":43.0,"value":110},
	"cargo":{"label":"Cargo freighter","focus":2.25,"life":18.75,"speed":17.0,"lit_speed":34.0,"value":180},
	"rescue":{"label":"Emergency launch","focus":0.95,"life":9.75,"speed":34.0,"lit_speed":55.0,"value":200},
	"cutter":{"label":"Fast cutter","focus":1.15,"life":11.25,"speed":42.0,"lit_speed":58.0,"value":90},
	"barge":{"label":"Heavy barge","focus":2.9,"life":21.75,"speed":13.0,"lit_speed":27.0,"value":240}}
const BEACON = Vector2(270,690)
# Rates multiply the pre-Round-Three unlit ring drain, with weather/reef/horn
# effects applied afterward. Round Two skipped guided drain entirely, so there
# was no nonzero lit rate to increase: use a quarter-rate baseline, then +25%.
const NEVER_GUIDED_DRAIN = 1.33
const GUIDED_UNLIT_DRAIN = 1.0
const GUIDED_LIT_BASE_DRAIN = 0.25
const GUIDED_LIT_DRAIN = GUIDED_LIT_BASE_DRAIN * 1.25
# 28px half-hull length plus the existing 20px harbor arrival radius. This is
# only a speed exception for guided hulls clipping the narrowing cone apex.
const NEAR_SHORE_RADIUS = 48.0
var config: Dictionary = {}
var boats: Array = []
var events: Array = []
var upgrades: Dictionary = {"lens":0,"focus":0,"harbor":0}
var time = 0.0
var angle = -PI/2.0
var rescued = 0
var lost = 0
var score = 0
var chain = 0
var best_chain = 0
var kind_rescues: Dictionary = {}
var seen: Array = []
var next_spawn = 0
var endless_spawn = 0.5
var mode = "campaign"
var mission = 0
var done = false
var won = false
var assisted = false
var horn_charges = 3
var horn_refill = 0.0
var horn_effect = 0.0
var horn_uses = 0
var serial = 0
var continued = false
var lost_boats: Array = []

func start(definition: Dictionary, levels: Dictionary, selected_mode: String = "campaign") -> void:
	config = definition.duplicate(true)
	upgrades = levels.duplicate(true)
	mode = selected_mode
	mission = int(config.get("id",0))
	boats.clear(); events.clear(); seen.clear(); kind_rescues.clear(); lost_boats.clear()
	time=0.0;angle=-PI/2.0;rescued=0;lost=0;score=0;chain=0;best_chain=0
	next_spawn=0;endless_spawn=0.5;done=false;won=false;assisted=false
	horn_charges=max_horn_charges();horn_refill=0.0;horn_effect=0.0;horn_uses=0;serial=0;continued=false

func beam_half_width() -> float:
	return (0.11 + float(upgrades.get("lens",0))*0.012) * (1.0-float(config.get("fog",0.0))*.25)

func aim(point: Vector2) -> void:
	var direction = point-BEACON
	if direction.length_squared() > 25.0:
		angle = clampf(direction.angle(),-PI+0.10,-0.10)

static func _area(points: PackedVector2Array) -> float:
	var total = 0.0
	for i in range(points.size()): total += points[i].cross(points[(i+1)%points.size()])
	return absf(total)*0.5

func beam_coverage(boat: Dictionary) -> float:
	# Clip the rendered 36x56 sprite footprint against the beam. This measures
	# footprint area (including transparent pixels), not only its center angle.
	var hull = PackedVector2Array()
	for corner in [Vector2(-18,-28),Vector2(18,-28),Vector2(18,28),Vector2(-18,28)]:
		hull.append(boat.pos+corner.rotated(float(boat.get("rotation",0.0))))
	var cone = PackedVector2Array([BEACON,BEACON+Vector2.from_angle(angle-beam_half_width())*1400.0,BEACON+Vector2.from_angle(angle+beam_half_width())*1400.0])
	var total = 0.0
	for polygon in Geometry2D.intersect_polygons(hull,cone): total += _area(polygon)
	return clampf(total/(36.0*56.0),0.0,1.0)

func lit(boat: Dictionary) -> bool:
	return beam_coverage(boat)>0.001

func ring_phase(boat: Dictionary) -> String:
	# `guided` remembers completed guidance for routing; `lit` is current hull
	# coverage. Moving the light away must not erase routing or imply immunity.
	if not bool(boat.get("guided",false)): return "never_guided"
	return "guided_lit" if bool(boat.get("lit",false)) else "guided_unlit"

func ring_drain(boat: Dictionary) -> float:
	match ring_phase(boat):
		"never_guided": return NEVER_GUIDED_DRAIN
		"guided_lit": return GUIDED_LIT_DRAIN
	return GUIDED_UNLIT_DRAIN

func near_shore_guidance(boat: Dictionary) -> bool:
	return bool(boat.get("guided",false)) and boat.has("pos") and boat.pos.distance_to(BEACON)<=NEAR_SHORE_RADIUS

func travel_speed(boat: Dictionary, coverage: float) -> float:
	var stats = KINDS[boat.kind]
	if near_shore_guidance(boat): return float(stats.lit_speed)
	return lerpf(float(stats.speed),float(stats.lit_speed),clampf(coverage,0.0,1.0))

func max_horn_charges() -> int:
	return 3+int(upgrades.get("horn",0))/2

func horn_duration() -> float:
	return 3.3+float(upgrades.get("horn",0))*0.35

func spawn(kind: String, x: float, drift: float = 0.0) -> void:
	if not KINDS.has(kind): kind = "skiff"
	serial += 1
	var stats = KINDS[kind]
	var lifetime = float(stats.life)+float(upgrades.get("harbor",0))*1.35
	boats.append({"id":serial,"kind":kind,"pos":Vector2(clampf(x,38,502),175),
		"guidance":0.0,"guided":false,"life":lifetime,"max_life":lifetime,"drift":drift,
		"rotation":0.0,"lit":false,"coverage":0.0})
	if kind not in seen: seen.append(kind)
	events.append({"event":"arrival","kind":kind})

func can_continue() -> bool:
	return done and not won and not continued and (not lost_boats.is_empty() or not boats.is_empty() or next_spawn<config.get("spawns",[]).size() or mode=="endless")

func continue_watch() -> bool:
	if not can_continue(): return false
	continued=true;assisted=true;done=false;won=false;lost=0;chain=0
	for previous in lost_boats:
		spawn(str(previous.kind),float(previous.x),float(previous.drift))
	lost_boats.clear()
	for boat in boats:
		boat.life=boat.max_life
	config.duration=maxf(float(config.get("duration",100.0)),time+70.0)
	horn_charges=maxi(horn_charges,1)
	events.append({"event":"continue"})
	return true

func foghorn() -> bool:
	if done or horn_charges <= 0: return false
	horn_charges -= 1
	horn_uses += 1
	horn_effect = horn_duration()
	events.append({"event":"horn"})
	return true

func can_flare() -> bool:
	if done or assisted: return false
	for boat in boats:
		if not bool(boat.guided): return true
	return false

func rescue_flare() -> bool:
	if not can_flare(): return false
	assisted = true
	for boat in boats:
		boat.guidance = 1.0
		boat.guided = true
	horn_effect = horn_duration()
	events.append({"event":"flare"})
	return true

func _goal_met() -> bool:
	if rescued < int(config.get("target",1)): return false
	var requirement = config.get("required_kind","")
	return requirement == "" or int(kind_rescues.get(requirement,0)) >= int(config.get("required_count",1))

func step(delta: float) -> void:
	if done or delta <= 0.0 or not is_finite(delta): return
	# Clamp individual steps against foreground stalls; UI never calls this while paused.
	var dt = minf(delta,0.05)
	time += dt
	horn_effect = maxf(0.0,horn_effect-dt)
	if horn_charges < max_horn_charges():
		horn_refill += dt
		var refill_time = 14.0/(1.0+float(upgrades.get("horn",0))*0.10)
		if horn_refill >= refill_time:
			horn_refill -= refill_time
			horn_charges += 1
	else: horn_refill = 0.0
	var schedule = config.get("spawns",[])
	if mode == "endless":
		if time >= endless_spawn:
			var kinds = KINDS.keys()
			spawn(kinds[serial%kinds.size()],65.0+float((serial*137)%410),sin(float(serial)*2.1)*18.0)
			endless_spawn += maxf(1.45,4.0-time/70.0)
	else:
		while next_spawn < schedule.size() and time >= float(schedule[next_spawn].time):
			var arrival = schedule[next_spawn]
			spawn(str(arrival.kind),float(arrival.x),float(arrival.get("drift",0)))
			next_spawn += 1
	var tide = float(config.get("tide",0.0))
	var storm = float(config.get("storm",0.0))
	var weather_pulse = 1.0 + (storm if fmod(time,15.0) > 10.0 else 0.0)
	for index in range(boats.size()-1,-1,-1):
		var boat = boats[index]
		var stats = KINDS[boat.kind]
		var coverage = beam_coverage(boat)
		boat.coverage = coverage
		boat.lit = coverage>0.001
		if not bool(boat.guided) and bool(boat.lit):
			var focus = (1.0+float(upgrades.get("focus",0))*0.13)/float(stats.focus)
			boat.guidance = minf(1.0,float(boat.guidance)+dt*focus*coverage)
			if float(boat.guidance) >= 1.0:
				boat.guided = true
				events.append({"event":"guided","kind":boat.kind})
		var slow = 0.25 if horn_effect > 0.0 else 1.0
		var danger = 1.0
		for reef in config.get("reefs",[]):
			if boat.pos.distance_to(Vector2(float(reef[0]),float(reef[1]))) < float(reef[2]): danger = 1.0+1.5/(1.0+float(upgrades.get("breakwater",0))*0.2)
		# Every active boat spends its ring budget, including the first completed
		# guidance frame and returning ships. Near-shore speed grants no protection.
		boat.life -= dt*weather_pulse*danger*slow*ring_drain(boat)
		if float(boat.life) <= 0.0:
			_lose_boat(index)
			continue
		var speed = travel_speed(boat,coverage)
		if bool(boat.guided):
			var toward = BEACON-boat.pos
			boat.rotation = toward.angle()+PI/2.0
			boat.pos += toward.normalized()*speed*dt
			if toward.length() <= 20.0:
				rescued += 1; chain += 1; best_chain=maxi(chain,best_chain)
				kind_rescues[boat.kind]=int(kind_rescues.get(boat.kind,0))+1
				score += int(stats.value)+mini(chain,10)*10
				events.append({"event":"rescue","kind":boat.kind,"pos":boat.pos})
				boats.remove_at(index)
			continue
		boat.pos += Vector2(float(boat.drift)+tide*weather_pulse,speed) * dt*slow
		boat.pos.x = clampf(boat.pos.x,32,508)
		boat.rotation = sin(time+float(boat.id))*0.05
		if boat.pos.y > BEACON.y+15.0: _lose_boat(index)

	var exhausted = mode != "endless" and next_spawn >= schedule.size() and boats.is_empty()
	if lost >= int(config.get("lives",3)) or exhausted or (mode != "endless" and time >= float(config.get("duration",100.0))):
		done = true
		won = mode != "endless" and _goal_met() and lost < int(config.get("lives",3))
		events.append({"event":"finished","won":won})

func _lose_boat(index: int) -> void:
	var boat = boats[index]
	lost += 1; chain = 0
	lost_boats.append({"kind":boat.kind,"x":boat.pos.x,"drift":boat.drift})
	events.append({"event":"lost","kind":boat.kind,"pos":boat.pos})
	boats.remove_at(index)

func result() -> Dictionary:
	return {"mode":mode,"mission":mission,"rescued":rescued,"lost":lost,"score":score,
		"won":won,"assisted":assisted,"continued":continued,"seen":seen.duplicate(),"seconds":int(floor(time)),
		"chain":best_chain,"horn_uses":horn_uses}
