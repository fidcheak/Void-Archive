class_name BuildingsDB

static var _built := false
static var _list: Array = []
static var _by_id: Dictionary = {}

static func get_list() -> Array:
	if not _built: _build()
	return _list

static func get_def(id: String) -> Dictionary:
	if not _built: _build()
	return _by_id.get(id, {})

static func _build() -> void:
	_list = [
		{
			"id": "scanner", "name": "Сканер данных",
			"desc": "Извлекает фрагменты из повреждённых секторов.",
			"cost": { "data": 15.0 }, "cost_mult": 1.15,
			"produces": { "data": 0.5 }, "consumes": { "energy": 1.0 },
			"category": "Данные", "icon": "С", "icon_color": Palette.AMBER,
		},
		{
			"id": "reactor", "name": "Реактор",
			"desc": "Питает оборудование архива.",
			"cost": { "data": 50.0 }, "cost_mult": 1.20,
			"produces": { "energy": 5.0 }, "consumes": {},
			"category": "Энергия", "icon": "Р", "icon_color": Palette.ENERGY,
		},
		{
			"id": "supercomputer", "name": "Суперкомпьютер",
			"desc": "Преобразует данные в вычислительную мощность.",
			"cost": { "data": 100.0 }, "cost_mult": 1.18,
			"produces": { "compute": 1.0 }, "consumes": { "energy": 3.0 },
			"category": "Вычисления", "icon": "К", "icon_color": Palette.COMPUTE,
		},
		{
			"id": "data_cluster", "name": "Дата-кластер",
			"desc": "Промышленная добыча. Требует колоссальных данных, вычислений и крипты, и жрёт прорву энергии.",
			"cost": { "data": 50000.0, "compute": 5000.0, "hsh": 10.0 }, "cost_mult": 1.30,
			"produces": { "data": 60.0 }, "consumes": { "energy": 60.0 },
			"requires_research": "m_power_grid",
			"category": "Данные", "icon": "Д", "icon_color": Palette.AMBER,
		},
		{
			"id": "fusion_reactor", "name": "Термоядерный реактор",
			"desc": "Мощный источник энергии.",
			"cost": { "data": 80000.0, "compute": 8000.0, "hsh": 15.0 }, "cost_mult": 1.30,
			"produces": { "energy": 80.0 }, "consumes": {},
			"requires_research": "en_fusion",
			"category": "Энергия", "icon": "Т", "icon_color": Palette.ENERGY,
		},
		{
			"id": "singularity_gen", "name": "Сингулярный генератор",
			"desc": "Колоссальная выработка энергии.",
			"cost": { "data": 1000000.0, "compute": 100000.0, "hsh": 50.0, "ent": 30.0 }, "cost_mult": 1.35,
			"produces": { "energy": 800.0 }, "consumes": {},
			"requires_research": "en_singularity",
			"category": "Энергия", "icon": "Σ", "icon_color": Palette.ENERGY,
		},
		{
			"id": "quantum_dc", "name": "Квантовый дата-центр",
			"desc": "Промышленная добыча данных. Жрёт прорву энергии.",
			"cost": { "data": 200000.0, "compute": 20000.0, "hsh": 25.0 }, "cost_mult": 1.32,
			"produces": { "data": 300.0 }, "consumes": { "energy": 300.0 },
			"requires_research": "m_industrial",
			"category": "Данные", "icon": "Q", "icon_color": Palette.AMBER,
		},
		{
			"id": "neural_net", "name": "Нейросеть",
			"desc": "Огромная вычислительная мощность. Жрёт прорву энергии.",
			"cost": { "data": 300000.0, "compute": 40000.0, "ent": 30.0 }, "cost_mult": 1.34,
			"produces": { "compute": 50.0 }, "consumes": { "energy": 200.0 },
			"requires_research": "c_neural",
			"category": "Вычисления", "icon": "N", "icon_color": Palette.COMPUTE,
		},
		{
			"id": "compute_node", "name": "Вычислительный узел",
			"desc": "Базовая обработка.",
			"cost": { "data": 800.0 }, "cost_mult": 1.25,
			"produces": { "compute": 1.0 }, "consumes": { "energy": 1.0 },
			"requires_research": "cd_1",
			"category": "Вычисления", "icon": "u", "icon_color": Palette.COMPUTE,
		},
		{
			"id": "compute_array", "name": "Массив процессоров",
			"desc": "Параллельные ядра.",
			"cost": { "data": 8000.0, "compute": 500.0 }, "cost_mult": 1.26,
			"produces": { "compute": 5.0 }, "consumes": { "energy": 5.0 },
			"requires_research": "cd_2",
			"category": "Вычисления", "icon": "a", "icon_color": Palette.COMPUTE,
		},
		{
			"id": "compute_cluster", "name": "Кластер",
			"desc": "Связанные узлы.",
			"cost": { "data": 50000.0, "compute": 3000.0, "hsh": 10.0 }, "cost_mult": 1.27,
			"produces": { "compute": 20.0 }, "consumes": { "energy": 20.0 },
			"requires_research": "cd_3",
			"category": "Вычисления", "icon": "c", "icon_color": Palette.COMPUTE,
		},
		{
			"id": "compute_grid", "name": "Сеть вычислений",
			"desc": "Распределённая мощность.",
			"cost": { "data": 250000.0, "compute": 15000.0, "hsh": 30.0 }, "cost_mult": 1.28,
			"produces": { "compute": 80.0 }, "consumes": { "energy": 80.0 },
			"requires_research": "cd_4",
			"category": "Вычисления", "icon": "g", "icon_color": Palette.COMPUTE,
		},
		{
			"id": "compute_matrix", "name": "Вычислительная матрица",
			"desc": "Тензорная решётка.",
			"cost": { "data": 1200000.0, "compute": 80000.0, "qbt": 20.0 }, "cost_mult": 1.29,
			"produces": { "compute": 300.0 }, "consumes": { "energy": 300.0 },
			"requires_research": "cd_5",
			"category": "Вычисления", "icon": "M", "icon_color": Palette.COMPUTE,
		},
		{
			"id": "compute_forge", "name": "Процессорная кузница",
			"desc": "Поток ядер.",
			"cost": { "data": 6000000.0, "compute": 400000.0, "qbt": 50.0 }, "cost_mult": 1.30,
			"produces": { "compute": 1200.0 }, "consumes": { "energy": 1200.0 },
			"requires_research": "cd_6",
			"category": "Вычисления", "icon": "F", "icon_color": Palette.COMPUTE,
		},
		{
			"id": "compute_quantum", "name": "Квантовый процессор",
			"desc": "Суперпозиция вычислений.",
			"cost": { "data": 30000000.0, "compute": 2000000.0, "nul": 30.0 }, "cost_mult": 1.30,
			"produces": { "compute": 5000.0 }, "consumes": { "energy": 5000.0 },
			"requires_research": "cd_7",
			"category": "Вычисления", "icon": "Q", "icon_color": Palette.COMPUTE,
		},
		{
			"id": "compute_hypercore", "name": "Гиперядро",
			"desc": "Свёрнутая логика.",
			"cost": { "data": 150000000.0, "compute": 10000000.0, "sig": 30.0 }, "cost_mult": 1.31,
			"produces": { "compute": 20000.0 }, "consumes": { "energy": 20000.0 },
			"requires_research": "cd_8",
			"category": "Вычисления", "icon": "H", "icon_color": Palette.COMPUTE,
		},
		{
			"id": "compute_omnimind", "name": "Омни-разум",
			"desc": "Всеобъемлющее мышление.",
			"cost": { "data": 700000000.0, "compute": 50000000.0, "ech": 20.0 }, "cost_mult": 1.32,
			"produces": { "compute": 80000.0 }, "consumes": { "energy": 80000.0 },
			"requires_research": "cd_9",
			"category": "Вычисления", "icon": "O", "icon_color": Palette.COMPUTE,
		},
		{
			"id": "compute_infinity", "name": "Бесконечный процессор",
			"desc": "Предел вычислительной мощи.",
			"cost": { "data": 4000000000.0, "compute": 300000000.0, "ech": 50.0 }, "cost_mult": 1.33,
			"produces": { "compute": 300000.0 }, "consumes": { "energy": 300000.0 },
			"requires_research": "cd_10",
			"category": "Вычисления", "icon": "∞", "icon_color": Palette.COMPUTE,
		},
	]
	_by_id.clear()
	for d in _list:
		_by_id[d["id"]] = d
	_built = true
