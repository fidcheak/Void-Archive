class_name BuildingsDB

static func get_list() -> Array:
	return [
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
	]
