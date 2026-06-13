class_name Labels

static func res_name(id: String) -> String:
	return String(_map().get(id, {}).get("name", id))

static func res_short(id: String) -> String:
	return String(_map().get(id, {}).get("short", id.to_upper()))

static func _map() -> Dictionary:
	var m := {}
	for cid in ResourcesDB.get_defs():
		m[cid] = ResourcesDB.get_defs()[cid]
	for c in CryptoDB.get_list():
		m[c["id"]] = c
	return m
