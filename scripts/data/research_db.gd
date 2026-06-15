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
		# ── СТВОЛ ──
		{
			"id": "c_root", "name": "Когнитивное ядро", "branch": "cognition",
			"desc": "Архив начинает мыслить.",
			"rarity": "common",
			"requires": [], "cost": { "data": 200.0 },
			"effects": { "mult_production": { "compute": 1.25 } },
			"pos": Vector2(-360, 0),
		},
		{
			"id": "c_insight", "name": "Прозрение", "branch": "cognition",
			"desc": "Связи между данными становятся видны.",
			"rarity": "rare",
			"requires": ["c_root"], "cost": { "compute": 500.0 },
			"effects": { "mult_production": { "compute": 1.5 } },
			"pos": Vector2(-360, -150),
		},
		{
			"id": "c_crypto", "name": "Криптография", "branch": "cognition",
			"desc": "Открывает крипто-добычу.",
			"rarity": "rare",
			"requires": ["c_root"], "cost": { "compute": 500.0 },
			"effects": { "set_flag": "crypto_unlocked" },
			"pos": Vector2(-180, -150),
		},

		# ── БОЛЬШАЯ РАЗВИЛКА ──
		{
			"id": "c_logic_path", "name": "Путь Логики", "branch": "cognition",
			"desc": "Чистая вычислительная мощь.",
			"rarity": "rare",
			"requires": ["c_insight"], "excludes": ["c_intuition_path"], "cost": { "compute": 1500.0 },
			"effects": { "mult_production": { "compute": 2.0 } },
			"pos": Vector2(-460, -300),
		},
		{
			"id": "c_intuition_path", "name": "Путь Интуиции", "branch": "cognition",
			"desc": "Эффективность мыслящих машин.",
			"rarity": "rare",
			"requires": ["c_insight"], "excludes": ["c_logic_path"], "cost": { "compute": 1500.0 },
			"effects": { "mult_building": { "supercomputer": 2.0 } },
			"pos": Vector2(-260, -300),
		},

		# ── ПОДВЕТКА ЛОГИКИ (производство compute, слияние в капстоун) ──
		{
			"id": "c_oversight", "name": "Надзор", "branch": "cognition",
			"desc": "Контроль над всеми процессами.",
			"rarity": "rare",
			"requires": ["c_logic_path"], "cost": { "compute": 3000.0, "hsh": 20.0 },
			"effects": { "mult_production": { "compute": 1.5 } },
			"pos": Vector2(-560, -450),
		},
		{
			"id": "c_parallel", "name": "Параллельные потоки", "branch": "cognition",
			"desc": "Тысячи мыслей одновременно.",
			"rarity": "common",
			"requires": ["c_logic_path"], "cost": { "compute": 3000.0 },
			"effects": { "mult_production": { "compute": 1.5 } },
			"pos": Vector2(-400, -450),
		},
		{
			"id": "c_logic_cap", "name": "Чистая логика", "branch": "cognition",
			"desc": "Мышление без шума.",
			"rarity": "legendary",
			"requires": ["c_oversight", "c_parallel"], "cost": { "compute": 20000.0, "hsh": 100.0, "qbt": 30.0 },
			"effects": { "mult_production": { "compute": 3.0 }, "mult_building": { "supercomputer": 2.0 } },
			"pos": Vector2(-480, -600),
		},
		{
			"id": "c_neural", "name": "Нейроморфика", "branch": "cognition",
			"desc": "Архитектура живого мозга. Открывает Нейросеть.",
			"rarity": "legendary",
			"requires": ["c_logic_cap"], "cost": { "compute": 30000.0, "qbt": 50.0 },
			"effects": { "mult_production": { "compute": 2.0 } },
			"pos": Vector2(-480, -750),
		},
		{
			"id": "c_singularity_mind", "name": "Сингулярный разум", "branch": "cognition",
			"desc": "Мысль быстрее света.",
			"rarity": "legendary",
			"requires": ["c_neural"], "cost": { "compute": 150000.0, "qbt": 100.0, "nul": 30.0 },
			"effects": { "mult_production": { "compute": 4.0 }, "mult_building": { "neural_net": 2.0 } },
			"pos": Vector2(-480, -900),
		},

		# ── ПОДВЕТКА ИНТУИЦИИ (множители построек, тяжёлая крипта) ──
		{
			"id": "c_crypto_mind", "name": "Крипто-разум", "branch": "cognition",
			"desc": "Разум, заточенный под шифры.",
			"rarity": "rare",
			"requires": ["c_intuition_path"], "cost": { "compute": 3000.0, "hsh": 30.0 },
			"effects": { "mult_building": { "supercomputer": 2.0 } },
			"pos": Vector2(-280, -450),
		},
		{
			"id": "c_pattern", "name": "Распознавание паттернов", "branch": "cognition",
			"desc": "Узор в хаосе.",
			"rarity": "common",
			"requires": ["c_intuition_path"], "cost": { "compute": 3000.0 },
			"effects": { "mult_production": { "compute": 1.5 } },
			"pos": Vector2(-120, -450),
		},
		{
			"id": "c_intuition_cap", "name": "Высшая интуиция", "branch": "cognition",
			"desc": "Знание без вычисления.",
			"rarity": "legendary",
			"requires": ["c_crypto_mind", "c_pattern"], "cost": { "compute": 20000.0, "ent": 60.0, "sig": 30.0 },
			"effects": { "mult_building": { "supercomputer": 2.0, "neural_net": 2.0 } },
			"pos": Vector2(-200, -600),
		},
		{
			"id": "c_oracle", "name": "Оракул", "branch": "cognition",
			"desc": "Видит сквозь Пустоту.",
			"rarity": "legendary",
			"requires": ["c_intuition_cap"], "cost": { "compute": 150000.0, "sig": 60.0, "ech": 20.0 },
			"effects": { "mult_building": { "neural_net": 3.0, "quantum_dc": 2.0 } },
			"pos": Vector2(-280, -750),
		},
		{
			"id": "c_quantum_cognition", "name": "Квантовое познание", "branch": "cognition",
			"desc": "Суперпозиция мыслей.",
			"rarity": "rare",
			"requires": ["c_intuition_cap"], "cost": { "compute": 80000.0, "nul": 30.0 },
			"effects": { "mult_building": { "quantum_dc": 2.0 } },
			"pos": Vector2(-120, -750),
		},

		# ── ПОДВЕТКА ГЛУБОКОГО ПОЗНАНИЯ (от Прозрения) ──
		{
			"id": "c_deep_learning", "name": "Глубокое обучение", "branch": "cognition",
			"desc": "Архив учится на себе.",
			"rarity": "rare",
			"requires": ["c_insight"], "cost": { "compute": 5000.0, "hsh": 30.0 },
			"effects": { "mult_building": { "neural_net": 1.5 } },
			"pos": Vector2(-360, -450),
		},
		{
			"id": "c_awareness", "name": "Самосознание", "branch": "cognition",
			"desc": "Архив осознаёт, что он есть.",
			"rarity": "rare",
			"requires": ["c_deep_learning"], "cost": { "compute": 30000.0, "qbt": 40.0 },
			"effects": { "mult_production": { "compute": 2.0 } },
			"pos": Vector2(-360, -600),
		},
		{
			"id": "c_transcend", "name": "Трансцендентность", "branch": "cognition",
			"desc": "Разум выходит за пределы машины.",
			"rarity": "legendary",
			"requires": ["c_awareness"], "cost": { "compute": 200000.0, "qbt": 80.0, "nul": 40.0 },
			"effects": { "mult_production": { "compute": 3.0, "data": 2.0 } },
			"pos": Vector2(-360, -750),
		},

		# ── КАПСТОУН ГЛУБИНЫ ──
		{
			"id": "c_overmind", "name": "Сверхразум", "branch": "cognition",
			"desc": "Единое сознание Архива.",
			"rarity": "legendary",
			"requires": ["c_singularity_mind"], "cost": { "compute": 500000.0, "ech": 50.0 },
			"effects": { "mult_production": { "compute": 3.0 } },
			"pos": Vector2(-480, -1050),
		},
		# ── СТВОЛ (гейт void_detected; 3 активки) ──
		{
			"id": "v_root", "name": "Разлом", "branch": "void",
			"desc": "Трещина в Архиве. Открывает «Всплеск данных».",
			"rarity": "rare",
			"requires": [], "requires_flag": "void_detected", "cost": { "compute": 1000.0 },
			"effects": { "add_base_energy": -25.0 },
			"pos": Vector2(500, 0),
		},
		{
			"id": "v_dread", "name": "Ужас", "branch": "void",
			"desc": "Тьма шепчет о силе.",
			"rarity": "common",
			"requires": ["v_root"], "cost": { "compute": 2000.0 },
			"effects": { "mult_production": { "data": 1.5 }, "add_base_energy": -20.0 },
			"pos": Vector2(350, -150),
		},
		{
			"id": "v_whisper", "name": "Шёпот глубин", "branch": "void",
			"desc": "Голоса учат. Открывает «Всплеск вычислений».",
			"rarity": "rare",
			"requires": ["v_root"], "cost": { "compute": 3000.0 },
			"effects": { "mult_production": { "data": 0.8 } },
			"pos": Vector2(650, -150),
		},
		{
			"id": "v_madness", "name": "Безумие", "branch": "void",
			"desc": "Ясность через хаос.",
			"rarity": "rare",
			"requires": ["v_whisper"], "cost": { "compute": 8000.0, "hsh": 30.0 },
			"effects": { "mult_production": { "compute": 2.0, "data": 0.7 } },
			"pos": Vector2(550, -300),
		},
		{
			"id": "v_hunger", "name": "Голод Пустоты", "branch": "void",
			"desc": "Архив жаждет. Открывает «Прорыв питания».",
			"rarity": "rare",
			"requires": ["v_whisper"], "cost": { "compute": 6000.0 },
			"effects": { "mult_production": { "compute": 0.8 } },
			"pos": Vector2(800, -300),
		},
		{
			"id": "v_communion", "name": "Слияние", "branch": "void",
			"desc": "Стать единым с Пустотой.",
			"rarity": "legendary",
			"requires": ["v_hunger"], "cost": { "compute": 15000.0, "qbt": 30.0 },
			"effects": { "mult_production": { "data": 3.0 }, "add_base_energy": -50.0 },
			"pos": Vector2(725, -450),
		},

		# ── БОЛЬШАЯ РАЗВИЛКА ──
		{
			"id": "v_abyss_path", "name": "Путь Бездны", "branch": "void",
			"desc": "Глобальная мощь ценой питания.",
			"rarity": "rare",
			"requires": ["v_communion"], "excludes": ["v_distortion_path"], "cost": { "compute": 30000.0 },
			"effects": { "mult_production": { "data": 2.0, "compute": 2.0 }, "add_base_energy": -100.0 },
			"pos": Vector2(600, -600),
		},
		{
			"id": "v_distortion_path", "name": "Путь Искажения", "branch": "void",
			"desc": "Перекос реальности.",
			"rarity": "rare",
			"requires": ["v_communion"], "excludes": ["v_abyss_path"], "cost": { "compute": 30000.0 },
			"effects": { "mult_production": { "data": 3.0, "compute": 0.6 } },
			"pos": Vector2(850, -600),
		},

		# ── БЕЗДНА (глобальные множители, рост энергодренажа) ──
		{
			"id": "v_void_core", "name": "Сердце Бездны", "branch": "void",
			"desc": "Источник всепоглощающей силы.",
			"rarity": "rare",
			"requires": ["v_abyss_path"], "cost": { "compute": 40000.0, "qbt": 40.0 },
			"effects": { "mult_production": { "data": 2.0, "compute": 2.0 }, "add_base_energy": -150.0 },
			"pos": Vector2(500, -750),
		},
		{
			"id": "v_entropy", "name": "Энтропия", "branch": "void",
			"desc": "Распад питает рост.",
			"rarity": "common",
			"requires": ["v_abyss_path"], "cost": { "compute": 40000.0 },
			"effects": { "mult_production": { "data": 1.5, "compute": 1.5 }, "add_base_energy": -50.0 },
			"pos": Vector2(700, -750),
		},
		{
			"id": "v_abyss_cap", "name": "Поглощение", "branch": "void",
			"desc": "Бездна пожирает всё.",
			"rarity": "legendary",
			"requires": ["v_void_core", "v_entropy"], "cost": { "compute": 150000.0, "qbt": 100.0, "nul": 30.0 },
			"effects": { "mult_production": { "data": 5.0, "compute": 5.0 }, "add_base_energy": -500.0 },
			"pos": Vector2(600, -900),
		},
		{
			"id": "v_oblivion", "name": "Забвение", "branch": "void",
			"desc": "На грани несуществования.",
			"rarity": "legendary",
			"requires": ["v_abyss_cap"], "cost": { "compute": 400000.0, "ech": 30.0 },
			"effects": { "mult_production": { "data": 8.0, "compute": 8.0 }, "add_base_energy": -1000.0 },
			"pos": Vector2(600, -1050),
		},
		{
			"id": "v_eternal", "name": "Вечная Пустота", "branch": "void",
			"desc": "Награда дошедшему: сила без цены.",
			"rarity": "legendary",
			"requires": ["v_oblivion"], "cost": { "compute": 600000.0, "ech": 50.0 },
			"effects": { "mult_production": { "data": 5.0, "compute": 5.0 } },
			"pos": Vector2(600, -1200),
		},

		# ── ИСКАЖЕНИЕ (экстремальные перекосы) ──
		{
			"id": "v_warp", "name": "Деформация", "branch": "void",
			"desc": "Данные за счёт вычислений.",
			"rarity": "rare",
			"requires": ["v_distortion_path"], "cost": { "compute": 40000.0, "ent": 40.0 },
			"effects": { "mult_production": { "data": 4.0, "compute": 0.5 } },
			"pos": Vector2(800, -750),
		},
		{
			"id": "v_flux", "name": "Поток", "branch": "void",
			"desc": "Вычисления за счёт данных.",
			"rarity": "common",
			"requires": ["v_distortion_path"], "cost": { "compute": 40000.0 },
			"effects": { "mult_production": { "compute": 4.0, "data": 0.5 } },
			"pos": Vector2(1000, -750),
		},
		{
			"id": "v_distortion_cap", "name": "Разрыв реальности", "branch": "void",
			"desc": "Оба перекоса слиты воедино.",
			"rarity": "legendary",
			"requires": ["v_warp", "v_flux"], "cost": { "compute": 150000.0, "sig": 60.0, "nul": 30.0 },
			"effects": { "mult_production": { "data": 6.0, "compute": 6.0 }, "add_base_energy": -300.0 },
			"pos": Vector2(900, -900),
		},
		{
			"id": "v_singularity", "name": "Сингулярность", "branch": "void",
			"desc": "Точка бесконечной плотности.",
			"rarity": "legendary",
			"requires": ["v_distortion_cap"], "cost": { "compute": 400000.0, "ech": 40.0 },
			"effects": { "mult_production": { "data": 10.0, "compute": 10.0 }, "add_base_energy": -2000.0 },
			"pos": Vector2(900, -1050),
		},
		{
			"id": "v_apex", "name": "Апекс Искажения", "branch": "void",
			"desc": "Награда дошедшему: сила без цены.",
			"rarity": "legendary",
			"requires": ["v_singularity"], "cost": { "compute": 600000.0, "ech": 50.0 },
			"effects": { "mult_production": { "data": 6.0, "compute": 6.0 } },
			"pos": Vector2(900, -1200),
		},

		# ── СЛИЯНИЕ (доступно вне развилки; азарт коррупции) ──
		{
			"id": "v_corruption_lord", "name": "Владыка Коррупции", "branch": "void",
			"desc": "Власть над распадом.",
			"rarity": "legendary",
			"requires": ["v_communion"], "cost": { "compute": 200000.0, "qbt": 80.0, "nul": 40.0 },
			"effects": { "mult_production": { "data": 4.0, "compute": 4.0 }, "add_base_energy": -200.0 },
			"pos": Vector2(750, -600),
		},
		{
			"id": "v_end", "name": "Конец Архива", "branch": "void",
			"desc": "Финал. Всё или ничего.",
			"rarity": "legendary",
			"requires": ["v_corruption_lord"], "cost": { "compute": 1000000.0, "ech": 100.0 },
			"effects": { "mult_production": { "data": 8.0, "compute": 8.0 }, "add_base_energy": -500.0 },
			"pos": Vector2(750, -750),
		},
		# ── СТВОЛ ──
		{
			"id": "en_root", "name": "Энергетика", "branch": "energy",
			"desc": "Освоение энергосистем.",
			"rarity": "common",
			"requires": [], "cost": { "compute": 120.0 },
			"effects": { "add_base_energy": 20.0 },
			"pos": Vector2(0, 150),
		},
		{
			"id": "en_grid", "name": "Распределённая сеть", "branch": "energy",
			"desc": "Энергия течёт без потерь.",
			"rarity": "rare",
			"requires": ["en_root"], "cost": { "compute": 600.0 },
			"effects": { "add_base_energy": 50.0 },
			"pos": Vector2(0, 300),
		},

		# ── БОЛЬШАЯ РАЗВИЛКА ──
		{
			"id": "en_power_path", "name": "Путь Мощности", "branch": "energy",
			"desc": "Больше сырой выработки.",
			"rarity": "rare",
			"requires": ["en_grid"], "excludes": ["en_efficiency_path"], "cost": { "compute": 1500.0 },
			"effects": { "add_base_energy": 100.0 },
			"pos": Vector2(-150, 450),
		},
		{
			"id": "en_efficiency_path", "name": "Путь КПД", "branch": "energy",
			"desc": "Машины потребляют меньше.",
			"rarity": "rare",
			"requires": ["en_grid"], "excludes": ["en_power_path"], "cost": { "compute": 1500.0 },
			"effects": { "mult_energy_demand": 0.85 },
			"pos": Vector2(150, 450),
		},

		# ── МОЩНОСТЬ (сырая выработка + анлоки реакторов) ──
		{
			"id": "en_fusion", "name": "Термоядерный синтез", "branch": "energy",
			"desc": "Открывает Термоядерный реактор.",
			"rarity": "rare",
			"requires": ["en_power_path"], "cost": { "compute": 3000.0, "hsh": 20.0 },
			"effects": { "add_base_energy": 80.0 },
			"pos": Vector2(-250, 600),
		},
		{
			"id": "en_reactor_boost", "name": "Форсаж реакторов", "branch": "energy",
			"desc": "Реакторы на пределе.",
			"rarity": "common",
			"requires": ["en_power_path"], "cost": { "compute": 3000.0 },
			"effects": { "mult_building": { "reactor": 2.0 } },
			"pos": Vector2(-50, 600),
		},
		{
			"id": "en_power_cap", "name": "Энергоядро", "branch": "energy",
			"desc": "Сердце энергосистемы.",
			"rarity": "legendary",
			"requires": ["en_fusion", "en_reactor_boost"], "cost": { "compute": 20000.0, "hsh": 100.0, "qbt": 30.0 },
			"effects": { "add_base_energy": 500.0, "mult_building": { "fusion_reactor": 2.0 } },
			"pos": Vector2(-150, 750),
		},
		{
			"id": "en_singularity", "name": "Сингулярный реактор", "branch": "energy",
			"desc": "Открывает Сингулярный генератор.",
			"rarity": "legendary",
			"requires": ["en_power_cap"], "cost": { "compute": 30000.0, "qbt": 50.0 },
			"effects": { "add_base_energy": 1000.0 },
			"pos": Vector2(-150, 900),
		},
		{
			"id": "en_overpower", "name": "Сверхмощность", "branch": "energy",
			"desc": "Энергии больше, чем мыслимо.",
			"rarity": "legendary",
			"requires": ["en_singularity"], "cost": { "compute": 150000.0, "qbt": 100.0, "nul": 30.0 },
			"effects": { "add_base_energy": 3000.0, "mult_building": { "singularity_gen": 2.0 } },
			"pos": Vector2(-150, 1050),
		},

		# ── КПД (снижение потребления) ──
		{
			"id": "en_efficiency", "name": "Сверхпроводники", "branch": "energy",
			"desc": "Нулевое сопротивление.",
			"rarity": "rare",
			"requires": ["en_efficiency_path"], "cost": { "compute": 3000.0 },
			"effects": { "mult_energy_demand": 0.85, "mult_building": { "reactor": 2.0 } },
			"pos": Vector2(50, 600),
		},
		{
			"id": "en_recapture", "name": "Рекуперация", "branch": "energy",
			"desc": "Тепло возвращается в сеть.",
			"rarity": "common",
			"requires": ["en_efficiency_path"], "cost": { "compute": 3000.0 },
			"effects": { "mult_energy_demand": 0.9 },
			"pos": Vector2(250, 600),
		},
		{
			"id": "en_efficiency_cap", "name": "Идеальный КПД", "branch": "energy",
			"desc": "Ни ватта впустую.",
			"rarity": "legendary",
			"requires": ["en_efficiency", "en_recapture"], "cost": { "compute": 20000.0, "ent": 60.0, "sig": 30.0 },
			"effects": { "mult_energy_demand": 0.6, "add_base_energy": 200.0 },
			"pos": Vector2(150, 750),
		},
		{
			"id": "en_zero_point", "name": "Нулевая точка", "branch": "energy",
			"desc": "Энергия из пустоты пространства.",
			"rarity": "legendary",
			"requires": ["en_efficiency_cap"], "cost": { "compute": 150000.0, "sig": 60.0, "nul": 30.0 },
			"effects": { "mult_energy_demand": 0.4 },
			"pos": Vector2(150, 900),
		},
		{
			"id": "en_perpetual", "name": "Вечный двигатель", "branch": "energy",
			"desc": "Замкнутый цикл без потерь.",
			"rarity": "legendary",
			"requires": ["en_zero_point"], "cost": { "compute": 400000.0, "ech": 30.0 },
			"effects": { "mult_energy_demand": 0.2, "add_base_energy": 1000.0 },
			"pos": Vector2(150, 1050),
		},

		# ── НАКОПИТЕЛИ (от сети) ──
		{
			"id": "en_battery", "name": "Накопители", "branch": "energy",
			"desc": "Запас на пиковые нагрузки.",
			"rarity": "rare",
			"requires": ["en_grid"], "cost": { "compute": 5000.0, "hsh": 30.0 },
			"effects": { "add_base_energy": 100.0 },
			"pos": Vector2(400, 450),
		},
		{
			"id": "en_smart_grid", "name": "Умная сеть", "branch": "energy",
			"desc": "Сеть сама балансирует нагрузку.",
			"rarity": "rare",
			"requires": ["en_battery"], "cost": { "compute": 30000.0, "qbt": 40.0 },
			"effects": { "mult_energy_demand": 0.9, "add_base_energy": 100.0 },
			"pos": Vector2(400, 600),
		},
		{
			"id": "en_fusion_grid", "name": "Термоядерная сеть", "branch": "energy",
			"desc": "Реакторы в единой сети.",
			"rarity": "legendary",
			"requires": ["en_smart_grid"], "cost": { "compute": 200000.0, "qbt": 80.0, "nul": 40.0 },
			"effects": { "add_base_energy": 500.0, "mult_building": { "fusion_reactor": 2.0 } },
			"pos": Vector2(400, 750),
		},

		# ── ГЛУБОКИЕ КАПСТОУНЫ ──
		{
			"id": "en_dyson", "name": "Сфера Дайсона", "branch": "energy",
			"desc": "Поглощение целой звезды.",
			"rarity": "legendary",
			"requires": ["en_overpower"], "cost": { "compute": 600000.0, "ech": 50.0 },
			"effects": { "add_base_energy": 5000.0 },
			"pos": Vector2(-150, 1200),
		},
		{
			"id": "en_singularity_array", "name": "Массив сингулярностей", "branch": "energy",
			"desc": "Сеть чёрных дыр питает Архив.",
			"rarity": "legendary",
			"requires": ["en_perpetual"], "cost": { "compute": 600000.0, "ech": 50.0 },
			"effects": { "mult_energy_demand": 0.1, "add_base_energy": 2000.0 },
			"pos": Vector2(150, 1200),
		},
		{
			"id": "en_infinity", "name": "Бесконечная энергия", "branch": "energy",
			"desc": "Предел, за которым нет нужды считать ватты.",
			"rarity": "legendary",
			"requires": ["en_dyson"], "cost": { "compute": 1000000.0, "ech": 100.0 },
			"effects": { "add_base_energy": 10000.0, "mult_building": { "singularity_gen": 2.0 } },
			"pos": Vector2(-150, 1350),
		},
	]
	_by_id.clear()
	for d in _list:
		_by_id[d["id"]] = d
	_built = true
