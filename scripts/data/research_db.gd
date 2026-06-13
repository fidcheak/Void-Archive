class_name ResearchDB

# опционально для группировки/заголовков; Сознание и Пустота — заглушки на L5
static func get_branches() -> Array:
	return [
		{ "id": "machines",  "name": "Путь Машин",    "color": Palette.AMBER,  "locked": false },
		{ "id": "cognition", "name": "Путь Сознания", "color": Palette.ENERGY, "locked": false },
		{ "id": "void",      "name": "Путь Пустоты",  "color": Palette.VOID,   "locked": true },
	]

static func get_list() -> Array:
	return [
		{
			"id": "m_basic_analysis", "name": "Базовый анализ", "branch": "machines",
			"desc": "Структурирование сырых фрагментов.",
			"requires": [], "cost": { "compute": 10.0 },
			"effects": { "mult_production": { "data": 1.25 } },
			"pos": Vector2(0, 0),
		},
		{
			"id": "m_auto_scan", "name": "Автоматическое сканирование", "branch": "machines",
			"desc": "Сканеры работают эффективнее.",
			"requires": ["m_basic_analysis"], "cost": { "compute": 50.0 },
			"effects": { "mult_building": { "scanner": 1.5 } },
			"excludes": ["m_data_compression"],
			"pos": Vector2(-130, -150),
		},
		{
			"id": "m_data_compression", "name": "Сжатие данных", "branch": "machines",
			"desc": "Больше данных из тех же источников.",
			"requires": ["m_basic_analysis"], "cost": { "compute": 75.0 },
			"effects": { "mult_production": { "data": 1.5 } },
			"excludes": ["m_auto_scan"],
			"pos": Vector2(130, -150),
		},
		{
			"id": "m_power_grid", "name": "Энергосеть v2", "branch": "machines",
			"desc": "Подключены резервные контуры архива.",
			"requires": ["m_auto_scan"], "cost": { "compute": 120.0 },
			"effects": { "add_base_energy": 10.0 },
			"pos": Vector2(-130, -300),
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
	]
