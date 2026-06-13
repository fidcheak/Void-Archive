class_name MetaDB

static func get_def(id: String) -> Dictionary:
	for m in get_list():
		if m["id"] == id:
			return m
	return {}

static func get_list() -> Array:
	return [
		{ "id": "e_autoclick", "name": "Эхо-курсор", "requires": [], "cost": 1.0,
		  "desc": "Извлечение фрагментов продолжается само.",
		  "effects": { "autoclick": true } },
		{ "id": "e_residual_memory", "name": "Остаточная память", "requires": [], "cost": 2.0,
		  "desc": "Прошлые линии усиливают производство (×1.5).",
		  "effects": { "mult_production": 1.5 } },
		{ "id": "e_fragment_past", "name": "Фрагмент прошлого", "requires": ["e_residual_memory"], "cost": 4.0,
		  "desc": "Каждая новая линия начинается с задела данных.",
		  "effects": { "start_data": 500.0 } },
		{ "id": "e_time_resonance", "name": "Резонанс времени", "requires": ["e_fragment_past"], "cost": 6.0,
		  "desc": "Сворачивание линий даёт больше эхо (×1.5).",
		  "effects": { "echo_gain_mult": 1.5 } },
	]
