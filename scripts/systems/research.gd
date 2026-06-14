class_name Research

static var _dirty := true
static var _prod_mult: Dictionary = {}
static var _building_mult: Dictionary = {}
static var _base_energy_bonus := 0.0

static func mark_dirty() -> void:
	_dirty = true

static func get_def(id: String) -> Dictionary:
	return ResearchDB.get_def(id)

static func is_owned(id: String) -> bool:
	return GameState.research.has(id)

static func prereqs_met(id: String) -> bool:
	for p in get_def(id).get("requires", []):
		if not is_owned(p):
			return false
	return true

static func is_excluded(id: String) -> bool:
	var d := get_def(id)
	for owned_id in GameState.research:
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
	return (not is_owned(id)) and prereqs_met(id)

static func can_afford(id: String) -> bool:
	for res in get_def(id).get("cost", {}):
		if GameState.get_resource(res) < float(get_def(id)["cost"][res]):
			return false
	return true

static func can_research(id: String) -> bool:
	return is_available(id) and can_afford(id)

static func research(id: String) -> bool:
	if get_def(id).get("stub", false):
		return false
	if not can_research(id):
		return false
	for res in get_def(id).get("cost", {}):
		GameState.add_resource(res, -float(get_def(id)["cost"][res]))
	GameState.research[id] = true
	mark_dirty()
	Events.research_completed.emit(id)
	return true

# ---- множители для Production ----
static func _rebuild_cache() -> void:
	_prod_mult.clear()
	_building_mult.clear()
	_base_energy_bonus = 0.0
	for id in GameState.research:
		var eff: Dictionary = get_def(id).get("effects", {})
		for res in eff.get("mult_production", {}):
			_prod_mult[res] = float(_prod_mult.get(res, 1.0)) * float(eff["mult_production"][res])
		for bid in eff.get("mult_building", {}):
			_building_mult[bid] = float(_building_mult.get(bid, 1.0)) * float(eff["mult_building"][bid])
		_base_energy_bonus += float(eff.get("add_base_energy", 0.0))
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
