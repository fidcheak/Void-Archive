class_name Research

const COST_PER_LEVEL := 1.7   # рост цены за уровень (тюнится)

static var _dirty := true
static var _prod_mult: Dictionary = {}
static var _building_mult: Dictionary = {}
static var _base_energy_bonus := 0.0
static var _energy_demand_mult := 1.0

static func mark_dirty() -> void:
	_dirty = true

static func get_def(id: String) -> Dictionary:
	return ResearchDB.get_def(id)

static func level(id: String) -> int:
	return int(GameState.research.get(id, 0))

static func max_level(id: String) -> int:
	var eff: Dictionary = get_def(id).get("effects", {})
	var has_scaling := eff.has("mult_production") or eff.has("mult_building") or eff.has("add_base_energy") or eff.has("mult_energy_demand")
	if not has_scaling:
		return 1   # анлок/флаг-узлы — один ранг
	match String(get_def(id).get("rarity", "common")):
		"legendary": return 1
		"rare": return 3
		_: return 5

static func is_owned(id: String) -> bool:
	return level(id) >= 1

static func is_maxed(id: String) -> bool:
	return level(id) >= max_level(id)

static func next_cost(id: String) -> Dictionary:
	var lvl := level(id)
	var out := {}
	for res in get_def(id).get("cost", {}):
		out[res] = float(get_def(id)["cost"][res]) * pow(COST_PER_LEVEL, lvl)
	return out

static func prereqs_met(id: String) -> bool:
	for p in get_def(id).get("requires", []):
		if level(p) < 1:   # достаточно 1 ранга предпосылки
			return false
	return true

static func is_excluded(id: String) -> bool:
	var d := get_def(id)
	for owned_id in GameState.research:
		if int(GameState.research[owned_id]) <= 0: continue
		var od := get_def(owned_id)
		if id in od.get("excludes", []):
			return true
		if owned_id in d.get("excludes", []):
			return true
	return false

static func is_available(id: String) -> bool:
	var d := get_def(id)
	if d.get("stub", false):
		return false
	if is_excluded(id):
		return false
	var flag := String(d.get("requires_flag", ""))
	if flag != "" and not GameState.flags.get(flag, false):
		return false
	return (not is_maxed(id)) and prereqs_met(id)

static func can_afford(id: String) -> bool:
	var c := next_cost(id)
	for res in c:
		if GameState.get_resource(res) < float(c[res]):
			return false
	return true

static func can_research(id: String) -> bool:
	return is_available(id) and can_afford(id)

static func research(id: String) -> bool:
	if get_def(id).get("stub", false):
		return false
	if not can_research(id):
		return false
	var c := next_cost(id)
	for res in c:
		GameState.add_resource(res, -float(c[res]))
	GameState.research[id] = level(id) + 1
	if level(id) == 1:
		var sf := String(get_def(id).get("effects", {}).get("set_flag", ""))
		if sf != "":
			GameState.flags[sf] = true
			Events.log_message.emit("> МОДУЛЬ РАЗБЛОКИРОВАН", "sys")
	mark_dirty()
	Events.research_completed.emit(id)
	return true

# ---- множители для Production ----
static func _rebuild_cache() -> void:
	_prod_mult.clear()
	_building_mult.clear()
	_base_energy_bonus = 0.0
	_energy_demand_mult = 1.0
	for id in GameState.research:
		var lvl := int(GameState.research[id])
		if lvl <= 0: continue
		var eff: Dictionary = get_def(id).get("effects", {})
		for res in eff.get("mult_production", {}):
			_prod_mult[res] = float(_prod_mult.get(res, 1.0)) * pow(float(eff["mult_production"][res]), lvl)
		for bid in eff.get("mult_building", {}):
			_building_mult[bid] = float(_building_mult.get(bid, 1.0)) * pow(float(eff["mult_building"][bid]), lvl)
		_base_energy_bonus += float(eff.get("add_base_energy", 0.0)) * lvl
		_energy_demand_mult *= pow(float(eff.get("mult_energy_demand", 1.0)), lvl)
	_dirty = false

static func get_production_mult(resource: String) -> float:
	if _dirty: _rebuild_cache()
	return float(_prod_mult.get(resource, 1.0))

static func get_building_mult(building_id: String) -> float:
	if _dirty: _rebuild_cache()
	return float(_building_mult.get(building_id, 1.0))

static func get_base_energy_bonus() -> float:
	if _dirty: _rebuild_cache()
	return _base_energy_bonus

static func get_energy_demand_mult() -> float:
	if _dirty: _rebuild_cache()
	return _energy_demand_mult
