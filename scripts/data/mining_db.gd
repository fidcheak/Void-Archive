class_name MiningDB

static func get_rigs() -> Array:
	return [
		{ "id": "rig_hsh", "name": "Хеш-модуль", "desc": "Медленно добывает Хеш-осколки.",
		  "cost_base": 5000.0, "cost_mult": 1.25, "cost_res": "data",
		  "mines": { "hsh": 0.02 } },
		{ "id": "rig_ent", "name": "Энтропийный контур", "desc": "Медленно добывает Энтропий.",
		  "cost_base": 8000.0, "cost_mult": 1.25, "cost_res": "data",
		  "mines": { "ent": 0.015 } },
	]

static func get_upgrades() -> Array:
	return [
		{ "id": "mu_overclock", "name": "Разгон хешрейта", "desc": "Вся добыча ×2.",
		  "requires": [], "cost": { "hsh": 5.0 }, "effects": { "mine_mult": 2.0 } },
		{ "id": "mu_parallel", "name": "Параллельный майнинг", "desc": "Вся добыча ×1.5.",
		  "requires": ["mu_overclock"], "cost": { "ent": 8.0 }, "effects": { "mine_mult": 1.5 } },
	]

static func get_rig(id: String) -> Dictionary:
	for r in get_rigs():
		if r["id"] == id:
			return r
	return {}

static func get_upgrade(id: String) -> Dictionary:
	for u in get_upgrades():
		if u["id"] == id:
			return u
	return {}
