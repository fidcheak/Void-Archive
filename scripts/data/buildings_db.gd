class_name BuildingsDB

static func get_list() -> Array:
	return [
		{
			"id": "scanner", "name": "Сканер данных",
			"desc": "Извлекает фрагменты из повреждённых секторов.",
			"cost_base": 15.0, "cost_mult": 1.15, "cost_res": "data",
			"produces": { "data": 0.5 }, "consumes": { "energy": 1.0 },
		},
		{
			"id": "reactor", "name": "Реактор",
			"desc": "Питает оборудование архива.",
			"cost_base": 50.0, "cost_mult": 1.20, "cost_res": "data",
			"produces": { "energy": 5.0 }, "consumes": {},
		},
		{
			"id": "supercomputer", "name": "Суперкомпьютер",
			"desc": "Преобразует данные в вычислительную мощность.",
			"cost_base": 100.0, "cost_mult": 1.18, "cost_res": "data",
			"produces": { "compute": 1.0 }, "consumes": { "energy": 3.0 },
		},
	]
