class_name AbilitiesDB

static var _built := false
static var _list: Array = []
static var _by_id: Dictionary = {}

# effect: mult_production{res:factor} ИЛИ energy_add(float) — действует, пока баф активен
static func get_list() -> Array:
	if not _built: _build()
	return _list

static func get_def(id: String) -> Dictionary:
	if not _built: _build()
	return _by_id.get(id, {})

static func _build() -> void:
	_list = [
		{ "id": "data_burst", "name": "Всплеск данных",
		  "desc": "Производство Данных ×3 на 15с.",
		  "unlocked_by": "v_root", "duration": 15.0, "cooldown": 90.0,
		  "effect": { "mult_production": { "data": 3.0 } } },
		{ "id": "compute_burst", "name": "Всплеск вычислений",
		  "desc": "Производство Вычислений ×3 на 15с.",
		  "unlocked_by": "v_whisper", "duration": 15.0, "cooldown": 90.0,
		  "effect": { "mult_production": { "compute": 3.0 } } },
		{ "id": "energy_burst", "name": "Прорыв питания",
		  "desc": "+500 базовой энергии на 15с.",
		  "unlocked_by": "v_hunger", "duration": 15.0, "cooldown": 90.0,
		  "effect": { "energy_add": 500.0 } },
	]
	_by_id.clear()
	for d in _list:
		_by_id[d["id"]] = d
	_built = true
