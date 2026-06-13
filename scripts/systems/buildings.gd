class_name Buildings

static func get_def(id: String) -> Dictionary:
	for b in BuildingsDB.get_list():
		if b["id"] == id:
			return b
	return {}

static func count(id: String) -> int:
	return int(GameState.buildings.get(id, 0))

static func cost(id: String) -> Dictionary:
	var d := get_def(id)
	if d.is_empty(): return {}
	var n := count(id)
	var mult := float(d.get("cost_mult", 1.15))
	var out := {}
	for res in d.get("cost", {}):
		out[res] = float(d["cost"][res]) * pow(mult, n)
	return out

static func is_unlocked(id: String) -> bool:
	var req := String(get_def(id).get("requires_research", ""))
	return req == "" or Research.is_owned(req)

static func can_afford(id: String) -> bool:
	var c := cost(id)
	for res in c:
		if GameState.get_resource(res) < float(c[res]):
			return false
	return true

static func buy(id: String) -> bool:
	if not is_unlocked(id) or not can_afford(id):
		return false
	var c := cost(id)
	for res in c:
		GameState.add_resource(res, -float(c[res]))
	GameState.buildings[id] = count(id) + 1
	Events.building_purchased.emit(id, GameState.buildings[id])
	return true
