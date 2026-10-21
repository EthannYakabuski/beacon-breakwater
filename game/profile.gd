extends RefCounted
## Banked progress only. Active watches are deliberately not resumable saved runs.
const LIMIT = 1000000000
const MISSION_COUNT = 60
const UPGRADE_KEYS = ["lens", "focus", "harbor", "horn", "breakwater"]
const QUESTS = {"rescues": 12, "perfect": 2, "watches": 3}
var data: Dictionary = {}

func _init() -> void:
	data = {"version":1,"coins":140,"xp":0,"rescued":0,"watches":0,
		"perfect_watches":0,"best_endless":0,"missions":{},
		"upgrades":{"lens":0,"focus":0,"harbor":0,"horn":0,"breakwater":0},"seen":[],
		"day":-1,"login_day":-1,"streak":0,"daily":{"rescues":0,"perfect":0,"watches":0},
		"daily_claimed":[],"daily_best":{"_lifetime":0},"unlocked":[],
		"settings":{"sound":true,"music":true,"reduced_motion":false}}

static func integer(value: Variant, low: int = 0, high: int = LIMIT) -> int:
	if value is bool or not (value is int or value is float): return low
	if not is_finite(float(value)): return low
	return clampi(int(value),low,high)

func restore(raw: Variant) -> bool:
	if not raw is Dictionary or integer(raw.get("version",0)) != 1: return false
	for key in ["coins","xp","rescued","watches","perfect_watches","best_endless"]:
		data[key] = integer(raw.get(key,data[key]))
	for key in ["day","login_day"]: data[key] = integer(raw.get(key,-1),-1,1000000)
	data.streak = integer(raw.get("streak",0),0,7)
	var levels = raw.get("upgrades",{})
	if levels is Dictionary:
		for key in UPGRADE_KEYS: data.upgrades[key] = integer(levels.get(key,0),0,6)
	var missions = raw.get("missions",{})
	if missions is Dictionary:
		for key in missions:
			if str(key).is_valid_int() and int(key) in range(MISSION_COUNT):
				data.missions[str(int(key))] = integer(missions[key],0,3)
	var quests = raw.get("daily",{})
	if quests is Dictionary:
		for key in QUESTS: data.daily[key] = integer(quests.get(key,0))
	for key in ["seen","daily_claimed","unlocked"]:
		var items = raw.get(key,[])
		if items is Array:
			for item in items:
				if item is String and item.length() <= 64 and item not in data[key]: data[key].append(item)
	var best = raw.get("daily_best",{})
	if best is Dictionary:
		for key in best:
			if str(key).is_valid_int() and int(key) >= 0 and int(key) <= 1000000:
				data.daily_best[str(key)] = integer(best[key])
		data.daily_best["_lifetime"] = maxi(integer(best.get("_lifetime",0)),data.daily_best.size()-1)
	var settings = raw.get("settings",{})
	if settings is Dictionary:
		for key in data.settings:
			if settings.get(key) is bool: data.settings[key] = settings[key]
	return true

func level() -> int:
	return 1 + int(sqrt(float(data.xp) / 55.0))

func add_xp(amount: int) -> int:
	var before = level()
	data.xp = clampi(int(data.xp) + maxi(0,amount),0,LIMIT)
	var bonus = (level() - before) * 35
	data.coins = clampi(int(data.coins) + bonus,0,LIMIT)
	return bonus

func roll_day(today: int) -> void:
	if today > int(data.day):
		data.day = today
		data.daily = {"rescues":0,"perfect":0,"watches":0}
		data.daily_claimed = []
		# Bounded score history plus a durable distinct-day lifetime counter.
		for key in data.daily_best.keys():
			if str(key).is_valid_int() and int(key) < today - 14: data.daily_best.erase(key)

func claim_login(today: int) -> Dictionary:
	roll_day(today)
	if today <= int(data.login_day): return {}
	data.streak = int(data.streak) % 7 + 1 if int(data.login_day) == today - 1 else 1
	data.login_day = today
	var coins = 25 + int(data.streak) * 10 + (75 if int(data.streak) == 7 else 0)
	data.coins = clampi(int(data.coins)+coins,0,LIMIT)
	var bonus = add_xp(12)
	return {"coins":coins,"xp":12,"level_bonus":bonus,"streak":data.streak}

func claim_quest(key: String) -> Dictionary:
	if not QUESTS.has(key) or key in data.daily_claimed: return {}
	if int(data.daily.get(key,0)) < int(QUESTS[key]): return {}
	data.daily_claimed.append(key)
	data.coins = clampi(int(data.coins)+40,0,LIMIT)
	return {"coins":40,"xp":20,"level_bonus":add_xp(20)}

func upgrade_cost(key: String) -> int:
	if not UPGRADE_KEYS.has(key): return -1
	return int(round((90.0 if key=="horn" else 110.0 if key=="breakwater" else 70.0) * pow(1.65,float(data.upgrades[key]))))

func buy_upgrade(key: String) -> bool:
	var cost = upgrade_cost(key)
	if cost < 0 or int(data.upgrades[key]) >= 6 or int(data.coins) < cost: return false
	data.coins -= cost
	data.upgrades[key] += 1
	return true

func unlocked_mission() -> int:
	var next = 0
	while next < MISSION_COUNT and int(data.missions.get(str(next),0)) > 0: next += 1
	return mini(MISSION_COUNT-1,next)

func bank(result: Dictionary, today: int) -> Dictionary:
	## Caller banks one natural result once; no timer-only, abort or ad completion payout.
	roll_day(today)
	var rescued = integer(result.get("rescued",0),0,10000)
	var lost = integer(result.get("lost",0),0,10000)
	var score = integer(result.get("score",0))
	var mode = str(result.get("mode","campaign"))
	var mission = integer(result.get("mission",0),0,MISSION_COUNT-1)
	var won = result.get("won",false) is bool and bool(result.get("won",false))
	var continued = bool(result.get("continued",false))
	var perfect = won and lost == 0 and not continued
	var first = mode == "campaign" and won and int(data.missions.get(str(mission),0)) == 0
	var stars = (3 if perfect else 2 if lost <= 1 else 1) if won else 0
	var coins = rescued * 3 + (25 if first else 0) + (8 if perfect else 0)
	var xp = rescued * 4 + (20 if first else 0) + (10 if won else 0)
	data.rescued = mini(LIMIT,int(data.rescued)+rescued)
	data.watches = mini(LIMIT,int(data.watches)+1)
	data.perfect_watches = mini(LIMIT,int(data.perfect_watches)+(1 if perfect else 0))
	data.coins = mini(LIMIT,int(data.coins)+coins)
	if mode == "campaign" and won:
		data.missions[str(mission)] = maxi(stars,int(data.missions.get(str(mission),0)))
	if mode == "endless" and not bool(result.get("assisted",false)):
		data.best_endless = maxi(score,int(data.best_endless))
	var daily_bonus = 0
	if mode == "daily" and won and today == int(data.day):
		var day_key = str(today)
		if not data.daily_best.has(day_key):
			daily_bonus = 45
			data.coins = mini(LIMIT,int(data.coins)+daily_bonus)
			data.daily_best["_lifetime"] = mini(LIMIT,int(data.daily_best.get("_lifetime",0))+1)
		data.daily_best[day_key] = maxi(score,int(data.daily_best.get(day_key,0)))
	data.daily.rescues = mini(LIMIT,int(data.daily.rescues)+rescued)
	data.daily.watches = mini(LIMIT,int(data.daily.watches)+1)
	data.daily.perfect = mini(LIMIT,int(data.daily.perfect)+(1 if perfect else 0))
	for kind in result.get("seen",[]):
		if kind is String and kind not in data.seen: data.seen.append(kind)
	return {"coins":coins,"xp":xp,"level_bonus":add_xp(xp),"daily_bonus":daily_bonus,
		"first_clear":first,"stars":stars,"perfect":perfect}

func metrics() -> Dictionary:
	var coast = 0
	for chapter in range(MISSION_COUNT/5):
		var complete = true
		for index in range(chapter*5,chapter*5+5):
			if int(data.missions.get(str(index),0)) == 0: complete = false
		if complete: coast = chapter+1
	var total_upgrades = 0
	for key in UPGRADE_KEYS: total_upgrades += int(data.upgrades[key])
	return {"rescued":data.rescued,"watches":data.watches,"perfect_watches":data.perfect_watches,
		"keeper_level":level(),"coasts":coast,"upgrades":total_upgrades,
		"daily_watches":int(data.daily_best.get("_lifetime",0)),"best_endless":data.best_endless}
