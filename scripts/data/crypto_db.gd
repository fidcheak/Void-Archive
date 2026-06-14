class_name CryptoDB

static func get_list() -> Array:
	return [
		{ "id": "hsh", "name": "Хеш-осколок", "short": "HSH", "color": Color("e0a341") },
		{ "id": "ent", "name": "Энтропий", "short": "ENT", "color": Color("7fd0c0") },
		{ "id": "qbt", "name": "Квантум", "short": "QBT", "color": Color("6fb7ff") },
		{ "id": "sig", "name": "Сигнатура", "short": "SIG", "color": Color("e0c24f") },
		{ "id": "nul", "name": "Нуллон", "short": "NUL", "color": Color("9b7bff") },
		{ "id": "ech", "name": "Эхо-токен", "short": "ECH", "color": Color("d8d8e0") },
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
