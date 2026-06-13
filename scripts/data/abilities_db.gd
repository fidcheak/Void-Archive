class_name AbilitiesDB

# effect: mult_production{res:factor} ИЛИ energy_add(float) — действует, пока баф активен
static func get_list() -> Array:
	return [
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

static func get_def(id: String) -> Dictionary:
	for a in get_list():
		if a["id"] == id: return a
	return {}
