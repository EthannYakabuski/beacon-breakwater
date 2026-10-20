extends RefCounted
## Deterministic 2D rescue simulation. Native/clock/UI/storage independent.
const KINDS = {
	"skiff":{"label":"Skiff","focus":1.05,"life":17.0,"speed":24.0,"value":70},
	"sailor":{"label":"Sailer","focus":1.4,"life":21.0,"speed":17.0,"value":90},
	"cargo":{"label":"Cargo","focus":2.1,"life":25.0,"speed":13.0,"value":140},
	"rescue":{"label":"Emergency","focus":1.25,"life":13.0,"speed":23.0,"value":130},
	"cutter":{"label":"Cutter","focus":1.0,"life":15.0,"speed":29.0,"value":85},
	"barge":{"label":"Barge","focus":2.5,"life":29.0,"speed":11.0,"value":170}}
const BEACON = Vector2(270,740)
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

func start(definition: Dictionary, levels: Dictionary, selected_mode: String = "campaign") -> void:
	config = definition.duplicate(true)
	upgrades = levels.duplicate(true)
	mode = selected_mode
	mission = int(config.get("id",0))
	boats.clear(); events.clear(); seen.clear(); kind_rescues.clear()
	time=0.0;angle=-PI/2.0;rescued=0;lost=0;score=0;chain=0;best_chain=0
	next_spawn=0;endless_spawn=0.5;done=false;won=false;assisted=false
	horn_charges=3;horn_refill=0.0;horn_effect=0.0;horn_uses=0;serial=0

func beam_half_width() -> float:
	return (0.11 + float(upgrades.get("lens",0))*0.012) * (1.0-float(config.get("fog",0.0))*.25)

func aim(point: Vector2) -> void:
	var direction = point-BEACON
	if direction.length_squared() > 25.0:
		angle = clampf(direction.angle(),-PI+0.10,-0.10)

func lit(boat: Dictionary) -> bool:
	return absf(angle_difference(angle,(boat.pos-BEACON).angle())) <= beam_half_width()

func spawn(kind: String, x: float, drift: float = 0.0) -> void:
	if not KINDS.has(kind): kind = "skiff"
	serial += 1
	var stats = KINDS[kind]
	boats.append({"id":serial,"kind":kind,"pos":Vector2(clampf(x,38,502),175),
		"guidance":0.0,"guided":false,"life":float(stats.life)+float(upgrades.get("harbor",0))*1.8,
		"max_life":float(stats.life)+float(upgrades.get("harbor",0))*1.8,"drift":drift,
		"rotation":0.0,"lit":false})
	if kind not in seen: seen.append(kind)
	events.append({"event":"arrival","kind":kind})

func foghorn() -> bool:
	if done or horn_charges <= 0: return false
	horn_charges -= 1
	horn_uses += 1
	horn_effect = 3.3
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
	horn_effect = 3.3
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
	if horn_charges < 3:
		horn_refill += dt
		if horn_refill >= 14.0:
			horn_refill -= 14.0
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
		boat.lit = lit(boat)
		if bool(boat.guided):
			var toward = BEACON-boat.pos
			boat.rotation = toward.angle()+PI/2.0
			boat.pos += toward.normalized()*118.0*dt
			if toward.length() <= 20.0:
				rescued += 1; chain += 1; best_chain=maxi(chain,best_chain)
				kind_rescues[boat.kind]=int(kind_rescues.get(boat.kind,0))+1
				score += int(stats.value)+mini(chain,10)*10
				events.append({"event":"rescue","kind":boat.kind,"pos":boat.pos})
				boats.remove_at(index)
			continue
		var slow = 0.25 if horn_effect > 0.0 else 1.0
		var focus = (1.0+float(upgrades.get("focus",0))*0.13)/float(stats.focus)
		if bool(boat.lit):
			boat.guidance = minf(1.0,float(boat.guidance)+dt*focus)
			if float(boat.guidance) >= 1.0:
				boat.guided = true
				events.append({"event":"guided","kind":boat.kind})
				continue
		var danger = 1.0
		for reef in config.get("reefs",[]):
			if boat.pos.distance_to(Vector2(float(reef[0]),float(reef[1]))) < float(reef[2]): danger = 2.5
		boat.life -= dt*weather_pulse*danger*slow
		boat.pos += Vector2(float(boat.drift)+tide*weather_pulse,float(stats.speed)) * dt*slow*(0.55 if bool(boat.lit) else 1.0)
		boat.pos.x = clampf(boat.pos.x,32,508)
		boat.rotation = sin(time+float(boat.id))*0.05
		if float(boat.life) <= 0.0 or boat.pos.y > 725:
			lost += 1; chain = 0
			events.append({"event":"lost","kind":boat.kind,"pos":boat.pos})
			boats.remove_at(index)
	var exhausted = mode != "endless" and next_spawn >= schedule.size() and boats.is_empty()
	if lost >= int(config.get("lives",3)) or exhausted or (mode != "endless" and time >= float(config.get("duration",100.0))):
		done = true
		won = mode != "endless" and _goal_met() and lost < int(config.get("lives",3))
		events.append({"event":"finished","won":won})

func result() -> Dictionary:
	return {"mode":mode,"mission":mission,"rescued":rescued,"lost":lost,"score":score,
		"won":won,"assisted":assisted,"seen":seen.duplicate(),"seconds":int(floor(time)),
		"chain":best_chain,"horn_uses":horn_uses}
