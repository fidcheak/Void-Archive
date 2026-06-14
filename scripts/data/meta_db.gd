class_name MetaDB

static var _built := false
static var _list: Array = []
static var _by_id: Dictionary = {}

static func get_def(id: String) -> Dictionary:
	if not _built: _build()
	return _by_id.get(id, {})

static func get_list() -> Array:
	if not _built: _build()
	return _list

static func _build() -> void:
	_list = [
		{ "id": "e_autoclick", "name": "Эхо-курсор", "requires": [], "cost": 1.0,
		  "desc": "Извлечение фрагментов продолжается само.",
		  "effects": { "autoclick": true },
		  "pos": Vector2(0, 0) },
		{ "id": "e_residual_memory", "name": "Остаточная память", "requires": [], "cost": 2.0,
		  "desc": "Прошлые линии усиливают производство (×1.5).",
		  "effects": { "mult_production": 1.5 },
		  "pos": Vector2(170, 0) },
		{ "id": "e_fragment_past", "name": "Фрагмент прошлого", "requires": ["e_residual_memory"], "cost": 4.0,
		  "desc": "Каждая новая линия начинается с задела данных.",
		  "effects": { "start_data": 500.0 },
		  "pos": Vector2(170, -150) },
		{ "id": "e_time_resonance", "name": "Резонанс времени", "requires": ["e_fragment_past"], "cost": 6.0,
		  "desc": "Сворачивание линий даёт больше эхо (×1.5).",
		  "effects": { "echo_gain_mult": 1.5 },
		  "pos": Vector2(170, -300) },
	]
	_by_id.clear()
	for d in _list:
		_by_id[d["id"]] = d
	_built = true
