class_name Research

static func get_def(id: String) -> Dictionary:
	for r in ResearchDB.get_list():
		if r["id"] == id:
			return r
	return {}

static func is_owned(id: String) -> bool:
	return GameState.research.has(id)

static func prereqs_met(id: String) -> bool:
	for p in get_def(id).get("requires", []):
		if not is_owned(p):
			return false
	return true

static func is_available(id: String) -> bool:
	return not is_owned(id) and prereqs_met(id)

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
	Events.research_completed.emit(id)
	return true

# ---- множители для Production ----
static func get_production_mult(resource: String) -> float:
	var m := 1.0
	for id in GameState.research:
		var mp: Dictionary = get_def(id).get("effects", {}).get("mult_production", {})
		if mp.has(resource):
			m *= float(mp[resource])
	return m

static func get_building_mult(building_id: String) -> float:
	var m := 1.0
	for id in GameState.research:
		var mb: Dictionary = get_def(id).get("effects", {}).get("mult_building", {})
		if mb.has(building_id):
			m *= float(mb[building_id])
	return m

static func get_base_energy_bonus() -> float:
	var b := 0.0
	for id in GameState.research:
		b += float(get_def(id).get("effects", {}).get("add_base_energy", 0.0))
	return b
