class_name ResearchDB

# опционально для группировки/заголовков; Сознание и Пустота — заглушки на L5
static func get_branches() -> Array:
	return [
		{ "id": "machines",  "name": "Путь Машин",    "color": Palette.AMBER,  "locked": false },
		{ "id": "cognition", "name": "Путь Сознания", "color": Palette.ENERGY, "locked": true },
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
			"pos": Vector2(-130, -150),
		},
		{
			"id": "m_data_compression", "name": "Сжатие данных", "branch": "machines",
			"desc": "Больше данных из тех же источников.",
			"requires": ["m_basic_analysis"], "cost": { "compute": 75.0 },
			"effects": { "mult_production": { "data": 1.5 } },
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
			"id": "c_root", "name": "Путь Сознания", "branch": "cognition", "stub": true,
			"desc": "[ДАННЫЕ ПОВРЕЖДЕНЫ]",
			"requires": [], "cost": {}, "effects": {},
			"pos": Vector2(-360, 0),
		},
		{
			"id": "v_root", "name": "Путь Пустоты", "branch": "void", "stub": true,
			"desc": "[ДАННЫЕ ПОВРЕЖДЕНЫ]",
			"requires": [], "cost": {}, "effects": {},
			"pos": Vector2(360, 0),
		},
	]
