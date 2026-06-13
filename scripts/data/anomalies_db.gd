class_name AnomaliesDB

static func get_list() -> Array:
	return [
		{ "id": "signal_unknown", "name": "Неизвестный сигнал", "type": "signal",
		  "duration": 30.0, "effect": { "mult_production": 3.0 },
		  "base_weight": 1.0, "corruption_bias": -0.5,
		  "msg": "> ВХОДЯЩИЙ СИГНАЛ — ПРОИЗВОДСТВО УСИЛЕНО" },
		{ "id": "data_resonance", "name": "Резонанс данных", "type": "signal",
		  "duration": 0.0, "effect": { "instant_data_seconds": 60.0 },
		  "base_weight": 0.8, "corruption_bias": -0.2,
		  "msg": "> РЕЗОНАНС: ВСПЛЕСК ДАННЫХ" },
		{ "id": "interference", "name": "Помеха", "type": "glitch",
		  "duration": 30.0, "effect": { "mult_production": 0.5 },
		  "base_weight": 0.8, "corruption_bias": 0.6,
		  "msg": "> ПОМЕХА — ПРОИЗВОДСТВО СНИЖЕНО" },
		{ "id": "cascade_fault", "name": "Каскадный сбой", "type": "glitch",
		  "duration": 20.0, "effect": { "mult_production": 0.3 },
		  "base_weight": 0.4, "corruption_bias": 1.0,
		  "msg": "> КАСКАДНЫЙ СБОЙ" },
		{ "id": "void_whisper", "name": "Шёпот Пустоты", "type": "glitch",
		  "duration": 15.0, "effect": { "mult_production": 0.4 },
		  "base_weight": 0.2, "corruption_bias": 1.2, "lore": true,
		  "msg": "> ...ты слышишь это?" },
	]
