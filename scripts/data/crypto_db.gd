class_name CryptoDB

static var _built := false
static var _list: Array = []
static var _by_id: Dictionary = {}
static var _ids: Array = []

static func get_list() -> Array:
	if not _built: _build()
	return _list

static func get_def(id: String) -> Dictionary:
	if not _built: _build()
	return _by_id.get(id, {})

static func ids() -> Array:
	if not _built: _build()
	return _ids

static func _build() -> void:
	_list = [
		{ "id": "hsh", "name": "Хеш-осколок", "short": "HSH", "color": Color("e0a341") },
		{ "id": "ent", "name": "Энтропий", "short": "ENT", "color": Color("7fd0c0") },
		{ "id": "qbt", "name": "Квантум", "short": "QBT", "color": Color("6fb7ff") },
		{ "id": "sig", "name": "Сигнатура", "short": "SIG", "color": Color("e0c24f") },
		{ "id": "nul", "name": "Нуллон", "short": "NUL", "color": Color("9b7bff") },
		{ "id": "ech", "name": "Эхо-токен", "short": "ECH", "color": Color("d8d8e0") },
	]
	_by_id.clear()
	_ids.clear()
	for d in _list:
		_by_id[d["id"]] = d
		_ids.append(d["id"])
	_built = true
