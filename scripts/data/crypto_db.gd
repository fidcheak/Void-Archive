class_name CryptoDB

static func get_list() -> Array:
	return [
		{ "id": "hsh", "name": "Хеш-осколок", "short": "HSH", "color": Color("e0a341") },
		{ "id": "ent", "name": "Энтропий", "short": "ENT", "color": Color("7fd0c0") },
		# ЦЕЛЬ — 6 видов; остальные 4 добавятся в контентном слое
	]

static func get_def(id: String) -> Dictionary:
	for c in get_list():
		if c["id"] == id:
			return c
	return {}

static func ids() -> Array:
	var r := []
	for c in get_list():
		r.append(c["id"])
	return r
