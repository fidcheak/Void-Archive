class_name Buildings

static func get_def(id: String) -> Dictionary:
	for b in BuildingsDB.get_list():
		if b["id"] == id:
			return b
	return {}

static func count(id: String) -> int:
	return int(GameState.buildings.get(id, 0))

static func cost(id: String) -> float:
	var d := get_def(id)
	if d.is_empty(): return INF
	return float(d["cost_base"]) * pow(float(d["cost_mult"]), count(id))

static func can_afford(id: String) -> bool:
	var d := get_def(id)
	if d.is_empty(): return false
	return GameState.get_resource(String(d.get("cost_res", "data"))) >= cost(id)

static func buy(id: String) -> bool:
	if not can_afford(id): return false
	var d := get_def(id)
	var res := String(d.get("cost_res", "data"))
	GameState.add_resource(res, -cost(id))
	GameState.buildings[id] = count(id) + 1
	Events.building_purchased.emit(id, GameState.buildings[id])
	return true
