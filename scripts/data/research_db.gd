class_name ResearchDB

static var _built := false
static var _branches: Array = []
static var _list: Array = []
static var _by_id: Dictionary = {}

# опционально для группировки/заголовков; Сознание и Пустота — заглушки на L5
static func get_branches() -> Array:
	if not _built: _build()
	return _branches

static func get_list() -> Array:
	if not _built: _build()
	return _list

static func get_def(id: String) -> Dictionary:
	if not _built: _build()
	return _by_id.get(id, {})

static func _build() -> void:
	_branches = [
		{ "id": "machines",  "name": "Путь Машин",    "color": Palette.AMBER,  "locked": false },
		{ "id": "cognition", "name": "Путь Сознания", "color": Palette.ENERGY, "locked": false },
		{ "id": "void",      "name": "Путь Пустоты",  "color": Palette.VOID,   "locked": true },
		{ "id": "energy",    "name": "Путь Энергии",  "color": Palette.ENERGY_BRANCH, "locked": false },
	]

	_list = [
		# ── СТВОЛ ──
		{
			"id": "m_basic_analysis", "name": "Базовый анализ", "branch": "machines",
			"desc": "Архив учится извлекать смысл из шума.",
			"rarity": "common",
			"requires": [], "cost": { "compute": 100.0 },
			"effects": { "mult_production": { "data": 1.25 } },
			"pos": Vector2(0, 0),
		},
		{
			"id": "m_auto_scan", "name": "Автосканирование", "branch": "machines",
			"desc": "Сканеры работают без оператора.",
			"rarity": "common",
			"requires": ["m_basic_analysis"], "cost": { "compute": 200.0 },
			"effects": { "mult_building": { "scanner": 1.5 } },
			"pos": Vector2(0, -130),
		},
		{
			"id": "m_power_grid", "name": "Энергосеть v2", "branch": "machines",
			"desc": "Перестройка питающего контура. Открывает Дата-кластер.",
			"rarity": "rare",
			"requires": ["m_auto_scan"], "cost": { "compute": 600.0 },
			"effects": { "add_base_energy": 30.0 },
			"pos": Vector2(0, -260),
		},

		# ── БОЛЬШАЯ РАЗВИЛКА (взаимоисключение) ──
		{
			"id": "m_output_path", "name": "Путь Производства", "branch": "machines",
			"desc": "Всё ради сырого объёма данных.",
			"rarity": "rare",
			"requires": ["m_power_grid"], "excludes": ["m_efficiency_path"], "cost": { "compute": 1500.0 },
			"effects": { "mult_production": { "data": 2.0 } },
			"pos": Vector2(-160, -390),
		},
		{
			"id": "m_efficiency_path", "name": "Путь Эффективности", "branch": "machines",
			"desc": "Меньше энергии, больше отдачи с машины.",
			"rarity": "rare",
			"requires": ["m_power_grid"], "excludes": ["m_output_path"], "cost": { "compute": 1500.0 },
			"effects": { "mult_building": { "scanner": 2.0 }, "add_base_energy": 50.0 },
			"pos": Vector2(160, -390),
		},

		# ── ПОДВЕТКА ПРОИЗВОДСТВА (слияние в капстоун) ──
		{
			"id": "m_overclock", "name": "Разгон", "branch": "machines",
			"desc": "Сканеры за гранью режима.",
			"rarity": "common",
			"requires": ["m_output_path"], "cost": { "compute": 3000.0, "hsh": 20.0 },
			"effects": { "mult_production": { "data": 1.5 } },
			"pos": Vector2(-260, -510),
		},
		{
			"id": "m_parallel_proc", "name": "Параллельная обработка", "branch": "machines",
			"desc": "Кластеры делят нагрузку.",
			"rarity": "common",
			"requires": ["m_output_path"], "cost": { "compute": 3000.0 },
			"effects": { "mult_building": { "data_cluster": 1.5 } },
			"pos": Vector2(-100, -510),
		},
		{
			"id": "m_output_cap", "name": "Сверхпроизводство", "branch": "machines",
			"desc": "Конвейер данных на пределе физики.",
			"rarity": "legendary",
			"requires": ["m_overclock", "m_parallel_proc"], "cost": { "compute": 20000.0, "hsh": 100.0, "qbt": 30.0 },
			"effects": { "mult_production": { "data": 3.0 }, "mult_building": { "data_cluster": 2.0 } },
			"pos": Vector2(-180, -630),
		},
		{
			"id": "m_deep_scan", "name": "Глубокое сканирование", "branch": "machines",
			"desc": "Чтение из самых повреждённых секторов.",
			"rarity": "rare",
			"requires": ["m_output_cap"], "cost": { "compute": 50000.0, "qbt": 60.0 },
			"effects": { "mult_production": { "data": 2.5 } },
			"pos": Vector2(-180, -760),
		},
		{
			"id": "m_quantum_compress", "name": "Квантовое сжатие", "branch": "machines",
			"desc": "Бесконечная плотность данных.",
			"rarity": "legendary",
			"requires": ["m_deep_scan"], "cost": { "compute": 150000.0, "qbt": 100.0, "nul": 30.0 },
			"effects": { "mult_production": { "data": 4.0 }, "mult_building": { "quantum_dc": 2.0 } },
			"pos": Vector2(-180, -890),
		},

		# ── ПОДВЕТКА ЭФФЕКТИВНОСТИ (слияние в капстоун) ──
		{
			"id": "m_superconduct", "name": "Сверхпроводники", "branch": "machines",
			"desc": "Нулевые потери в сети.",
			"rarity": "common",
			"requires": ["m_efficiency_path"], "cost": { "compute": 3000.0 },
			"effects": { "add_base_energy": 80.0 },
			"pos": Vector2(100, -510),
		},
		{
			"id": "m_recycle", "name": "Рециркуляция", "branch": "machines",
			"desc": "Отходы вычислений идут в дело.",
			"rarity": "common",
			"requires": ["m_efficiency_path"], "cost": { "compute": 3000.0, "hsh": 20.0 },
			"effects": { "mult_building": { "scanner": 2.0 } },
			"pos": Vector2(260, -510),
		},
		{
			"id": "m_efficiency_cap", "name": "Идеальный КПД", "branch": "machines",
			"desc": "Ни джоуля впустую.",
			"rarity": "legendary",
			"requires": ["m_superconduct", "m_recycle"], "cost": { "compute": 20000.0, "hsh": 100.0, "ent": 30.0 },
			"effects": { "mult_building": { "scanner": 3.0, "data_cluster": 2.0 }, "add_base_energy": 200.0 },
			"pos": Vector2(180, -630),
		},
		{
			"id": "m_grid_optimize", "name": "Оптимизация сети", "branch": "machines",
			"desc": "Самонастройка энергопотоков.",
			"rarity": "rare",
			"requires": ["m_efficiency_cap"], "cost": { "compute": 50000.0, "ent": 60.0 },
			"effects": { "add_base_energy": 400.0 },
			"pos": Vector2(180, -760),
		},
		{
			"id": "m_zero_loss", "name": "Нулевые потери", "branch": "machines",
			"desc": "Машины почти не потребляют.",
			"rarity": "legendary",
			"requires": ["m_grid_optimize"], "cost": { "compute": 150000.0, "ent": 100.0, "sig": 30.0 },
			"effects": { "mult_building": { "scanner": 4.0, "data_cluster": 3.0 }, "add_base_energy": 1000.0 },
			"pos": Vector2(180, -890),
		},

		# ── ПОДВЕТКА ПРОМЫШЛЕННОСТИ (комбо-навыки через ветки) ──
		{
			"id": "m_factory", "name": "Фабрика данных", "branch": "machines",
			"desc": "Поточное производство кластеров.",
			"rarity": "rare",
			"requires": ["m_power_grid"], "cost": { "compute": 5000.0, "hsh": 30.0 },
			"effects": { "mult_building": { "data_cluster": 2.0 } },
			"pos": Vector2(-400, -390),
		},
		{
			"id": "m_industrial", "name": "Промышленный масштаб", "branch": "machines",
			"desc": "Сознание + Энергосеть рождают конвейер. Открывает Квантовый дата-центр.",
			"rarity": "legendary",
			"requires": ["m_factory"], "cost": { "compute": 30000.0, "hsh": 80.0, "qbt": 40.0 },
			"effects": { "mult_production": { "data": 2.0 } },
			"pos": Vector2(-400, -510),
		},
		{
			"id": "m_mass_production", "name": "Массовое производство", "branch": "machines",
			"desc": "Квантовые ДЦ штампуются.",
			"rarity": "rare",
			"requires": ["m_industrial"], "cost": { "compute": 80000.0, "hsh": 120.0 },
			"effects": { "mult_building": { "quantum_dc": 2.0 } },
			"pos": Vector2(-400, -650),
		},
		{
			"id": "m_singularity_factory", "name": "Сингулярная фабрика", "branch": "machines",
			"desc": "Слияние с Пустотой даёт невозможный выход.",
			"rarity": "legendary",
			"requires": ["m_mass_production"], "cost": { "compute": 300000.0, "qbt": 150.0, "ech": 20.0 },
			"effects": { "mult_production": { "data": 5.0 }, "mult_building": { "quantum_dc": 3.0 } },
			"pos": Vector2(-400, -790),
		},
		{
			"id": "m_overmind", "name": "Сверхразум", "branch": "machines",
			"desc": "Архив осознаёт собственное производство.",
			"rarity": "legendary",
			"requires": ["m_singularity_factory"], "cost": { "compute": 500000.0, "ech": 50.0 },
			"effects": { "mult_production": { "data": 3.0, "compute": 2.0 } },
			"pos": Vector2(-400, -920),
		},
		{
			"id": "c_root", "name": "Когнитивное ядро", "branch": "cognition",
			"desc": "Архив начинает осмыслять собственные данные.",
			"requires": [], "cost": { "compute": 30.0 },
			"effects": { "mult_production": { "compute": 1.5 } },
			"pos": Vector2(-360, 0),
		},
		{
			"id": "c_parallel", "name": "Параллельные потоки", "branch": "cognition",
			"desc": "Суперкомпьютеры работают согласованнее.",
			"requires": ["c_root"], "cost": { "compute": 90.0 },
			"effects": { "mult_building": { "supercomputer": 1.5 } },
			"pos": Vector2(-360, -150),
		},
		{
			"id": "c_deep", "name": "Глубокое обучение", "branch": "cognition",
			"desc": "Самооптимизация вычислений.",
			"requires": ["c_root"], "cost": { "compute": 140.0 },
			"effects": { "mult_production": { "compute": 2.0 } },
			"pos": Vector2(-520, -150),
		},
		{
			"id": "c_crypto", "name": "Криптография", "branch": "cognition",
			"desc": "Открывает крипто-добычу.",
			"rarity": "rare",
			"requires": ["c_root"], "cost": { "compute": 500.0 },
			"effects": { "set_flag": "crypto_unlocked" },
			"pos": Vector2(-200, -150),
		},
		{
			"id": "c_insight", "name": "Прозрение", "branch": "cognition",
			"desc": "Понимание данных ускоряет добычу.",
			"requires": ["c_parallel"], "cost": { "compute": 220.0 },
			"effects": { "mult_production": { "data": 1.4 } },
			"pos": Vector2(-360, -300),
		},
		{
			"id": "c_oversight", "name": "Надзор", "branch": "cognition",
			"desc": "Полный контроль вычислительного контура.",
			"requires": ["c_deep"], "cost": { "compute": 300.0 },
			"effects": { "mult_building": { "supercomputer": 2.0 } },
			"pos": Vector2(-520, -300),
		},
		{
			"id": "v_root", "name": "Разлом", "branch": "void",
			"desc": "Трещина в архиве ведёт глубже, чем следовало бы. Открывает доступ к «Всплеску данных», но непрерывно тянет энергию.",
			"requires": [], "requires_flag": "void_detected", "cost": { "compute": 150.0 },
			"effects": { "add_base_energy": -25.0 },
			"pos": Vector2(360, 0),
		},
		{
			"id": "v_whisper", "name": "Шёпот глубин", "branch": "void",
			"desc": "Что-то отвечает на запросы. Открывает «Всплеск вычислений», но искажает добычу Данных.",
			"requires": ["v_root"], "cost": { "compute": 300.0 },
			"effects": { "mult_production": { "data": 0.7 } },
			"pos": Vector2(360, -150),
		},
		{
			"id": "v_hunger", "name": "Голод Пустоты", "branch": "void",
			"desc": "Сканеры тянутся к тому, чего не должно быть. Открывает «Прорыв питания», но истощает Вычисления.",
			"requires": ["v_root"], "cost": { "compute": 420.0 },
			"effects": { "mult_production": { "compute": 0.7 } },
			"pos": Vector2(520, -150),
		},
		{
			"id": "v_communion", "name": "Слияние", "branch": "void",
			"desc": "Граница между тобой и архивом истончается. Огромный прирост Данных ценой тяжёлого энергодефицита.",
			"requires": ["v_whisper"], "cost": { "compute": 800.0 },
			"effects": { "mult_production": { "data": 3.0 }, "add_base_energy": -50.0 },
			"pos": Vector2(360, -300),
		},
		{
			"id": "en_root", "name": "Энергетика", "branch": "energy",
			"desc": "Освоение энергосистем архива.",
			"requires": [], "cost": { "compute": 120.0 },
			"effects": { "add_base_energy": 20.0 },
			"pos": Vector2(0, 150),
		},
		{
			"id": "en_fusion", "name": "Термоядерный синтез", "branch": "energy",
			"desc": "Открывает Термоядерный реактор.",
			"requires": ["en_root"], "excludes": ["en_efficiency"], "cost": { "compute": 400.0 },
			"effects": {},
			"pos": Vector2(-130, 300),
		},
		{
			"id": "en_efficiency", "name": "Сверхпроводники", "branch": "energy",
			"desc": "Существующие реакторы эффективнее (×2).",
			"requires": ["en_root"], "excludes": ["en_fusion"], "cost": { "compute": 400.0 },
			"effects": { "mult_building": { "reactor": 2.0 } },
			"pos": Vector2(130, 300),
		},
		{
			"id": "en_singularity", "name": "Сингулярный реактор", "branch": "energy",
			"desc": "Открывает Сингулярный генератор.",
			"requires": ["en_fusion"], "cost": { "compute": 2000.0 },
			"effects": {},
			"pos": Vector2(-130, 450),
		},
		{
			"id": "c_neural", "name": "Нейроморфика", "branch": "cognition",
			"desc": "Открывает Нейросеть.",
			"requires": ["c_oversight"], "cost": { "compute": 1200.0 },
			"effects": {},
			"pos": Vector2(-660, -300),
		},
	]
	_by_id.clear()
	for d in _list:
		_by_id[d["id"]] = d
	_built = true
