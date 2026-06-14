class_name MiningDB

static var _built := false
static var _rigs: Array = []
static var _rigs_by_id: Dictionary = {}
static var _upgrades: Array = []
static var _upgrades_by_id: Dictionary = {}

static func get_rigs() -> Array:
	if not _built: _build()
	return _rigs

static func get_upgrades() -> Array:
	if not _built: _build()
	return _upgrades

static func get_rig(id: String) -> Dictionary:
	if not _built: _build()
	return _rigs_by_id.get(id, {})

static func get_upgrade(id: String) -> Dictionary:
	if not _built: _build()
	return _upgrades_by_id.get(id, {})

static func _build() -> void:
	_rigs = [
		{ "id": "rig_hsh", "name": "Хеш-модуль", "desc": "Медленно добывает Хеш-осколки.",
		  "cost_base": 5000.0, "cost_mult": 1.25, "cost_res": "data",
		  "mines": { "hsh": 0.02 } },
		{ "id": "rig_ent", "name": "Энтропийный контур", "desc": "Медленно добывает Энтропий.",
		  "cost_base": 8000.0, "cost_mult": 1.25, "cost_res": "data",
		  "mines": { "ent": 0.015 } },
		{ "id": "rig_qbt", "name": "Квантовый ригер", "desc": "Добывает Квантум.",
		  "cost_base": 50000.0, "cost_mult": 1.28, "cost_res": "data",
		  "mines": { "qbt": 0.012 } },
		{ "id": "rig_sig", "name": "Сигнатурный модуль", "desc": "Добывает Сигнатуру.",
		  "cost_base": 200000.0, "cost_mult": 1.30, "cost_res": "data",
		  "mines": { "sig": 0.010 } },
		{ "id": "rig_nul", "name": "Нуллон-коллектор", "desc": "Добывает Нуллон.",
		  "cost_base": 800000.0, "cost_mult": 1.32, "cost_res": "data",
		  "mines": { "nul": 0.008 } },
		{ "id": "rig_ech", "name": "Эхо-резонатор", "desc": "Добывает Эхо-токены — медленно и редко.",
		  "cost_base": 3000000.0, "cost_mult": 1.35, "cost_res": "data",
		  "mines": { "ech": 0.006 } },
	]
	_upgrades = [
		{ "id": "mu_overclock", "name": "Разгон хешрейта", "desc": "Вся добыча ×2.",
		  "requires": [], "cost": { "hsh": 5.0 }, "effects": { "mine_mult": 2.0 } },
		{ "id": "mu_parallel", "name": "Параллельный майнинг", "desc": "Вся добыча ×1.5.",
		  "requires": ["mu_overclock"], "cost": { "ent": 8.0 }, "effects": { "mine_mult": 1.5 } },
		{ "id": "mu_quantum", "name": "Квантовый разгон", "desc": "Вся добыча ×2.",
		  "requires": ["mu_parallel"], "cost": { "qbt": 5.0 }, "effects": { "mine_mult": 2.0 } },
		{ "id": "mu_resonance", "name": "Резонанс сети", "desc": "Вся добыча ×2.",
		  "requires": ["mu_quantum"], "cost": { "sig": 5.0, "nul": 3.0 }, "effects": { "mine_mult": 2.0 } },
		{ "id": "mu_singularity", "name": "Сингулярный майнинг", "desc": "Вся добыча ×3.",
		  "requires": ["mu_resonance"], "cost": { "ech": 3.0 }, "effects": { "mine_mult": 3.0 } },
	]
	_rigs_by_id.clear()
	for d in _rigs:
		_rigs_by_id[d["id"]] = d
	_upgrades_by_id.clear()
	for d in _upgrades:
		_upgrades_by_id[d["id"]] = d
	_built = true
