class_name Production

const BASE_ENERGY := 10.0

static func recompute() -> Dictionary:
	var base_energy := BASE_ENERGY + Research.get_base_energy_bonus()
	var e_prod := base_energy
	var e_dem := 0.0
	for b in BuildingsDB.get_list():
		var n := float(Buildings.count(b["id"]))
		if n <= 0.0: continue
		e_prod += float(b.get("produces", {}).get("energy", 0.0)) * n
		e_dem += float(b.get("consumes", {}).get("energy", 0.0)) * n
	var ratio := 1.0
	if e_dem > 0.0:
		ratio = clampf(e_prod / e_dem, 0.0, 1.0)
	GameState.energy_production = e_prod
	GameState.energy_demand = e_dem
	GameState.power_ratio = ratio

	var rates := {}   # resource -> rate (накапливаемые; energy сюда НЕ входит)
	for b in BuildingsDB.get_list():
		var n := float(Buildings.count(b["id"]))
		if n <= 0.0: continue
		var consumes_energy: bool = float(b.get("consumes", {}).get("energy", 0.0)) > 0.0
		var mult := (ratio if consumes_energy else 1.0) * Research.get_building_mult(b["id"])
		for res in b.get("produces", {}):
			if res == "energy": continue
			var amt: float = float(b["produces"][res]) * n * mult * Research.get_production_mult(res)
			rates[res] = float(rates.get(res, 0.0)) + amt

	var global_mult := Corruption.get_production_bonus_mult() * Anomalies.get_active_production_mult()
	for res in rates.keys():
		rates[res] = float(rates[res]) * global_mult

	GameState.production_rates = rates
	GameLoop.current_data_rate = float(rates.get("data", 0.0))
	return { "rates": rates, "ratio": ratio }

static func update(delta: float) -> void:
	var r := recompute()
	for res in r["rates"]:
		var rate: float = r["rates"][res]
		if rate != 0.0:
			GameState.add_resource(res, rate * delta)

static func compute_rates() -> Dictionary:
	return recompute()["rates"]
