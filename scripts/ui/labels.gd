class_name Labels

static var _built := false
static var _cached_map: Dictionary = {}

static func res_name(id: String) -> String:
	return String(_map().get(id, {}).get("name", id))

static func res_short(id: String) -> String:
	return String(_map().get(id, {}).get("short", id.to_upper()))

static func _map() -> Dictionary:
	if not _built:
		_cached_map.clear()
		var defs := ResourcesDB.get_defs()
		for cid in defs:
			_cached_map[cid] = defs[cid]
		for c in CryptoDB.get_list():
			_cached_map[c["id"]] = c
		_built = true
	return _cached_map
