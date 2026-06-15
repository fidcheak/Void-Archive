class_name Mining

static var mining_ratio := 1.0   # 0..1, выставляется из Production по нехватке Вычислений

# ---- риги ----
static func rig_count(id: String) -> int:
	return int(GameState.crypto_rigs.get(id, 0))

static func rig_cost(id: String) -> float:
	var d := MiningDB.get_rig(id)
	if d.is_empty(): return INF
	return float(d["cost_base"]) * pow(float(d["cost_mult"]), rig_count(id))

static func can_buy_rig(id: String) -> bool:
	var d := MiningDB.get_rig(id)
	return (not d.is_empty()) and GameState.get_resource(String(d.get("cost_res", "data"))) >= rig_cost(id)

static func buy_rig(id: String) -> bool:
	if not GameState.flags.get("crypto_unlocked", false): return false
	if not can_buy_rig(id): return false
	var d := MiningDB.get_rig(id)
	GameState.add_resource(String(d.get("cost_res", "data")), -rig_cost(id))
	GameState.crypto_rigs[id] = rig_count(id) + 1
	Events.crypto_rig_bought.emit(id, GameState.crypto_rigs[id])
	return true

# ---- множитель разгона ----
static func mine_mult() -> float:
	var m := 1.0
	for id in GameState.mining_upgrades:
		m *= float(MiningDB.get_upgrade(id).get("effects", {}).get("mine_mult", 1.0))
	return m

# ---- скорости добычи ----
static func crypto_rate(crypto_id: String) -> float:
	var total := 0.0
	for r in MiningDB.get_rigs():
		var n := float(rig_count(r["id"]))
		if n <= 0.0: continue
		total += float(r.get("mines", {}).get(crypto_id, 0.0)) * n
	return total * mine_mult() * mining_ratio

static func total_compute_upkeep() -> float:
	var u := 0.0
	for r in MiningDB.get_rigs():
		u += float(r.get("compute_upkeep", 0.0)) * float(rig_count(r["id"]))
	return u

static func compute_crypto_rates() -> Dictionary:
	var rates := {}
	for cid in CryptoDB.ids():
		rates[cid] = crypto_rate(cid)
	return rates

static func update(delta: float) -> void:
	for cid in CryptoDB.ids():
		var rate := crypto_rate(cid)
		if rate != 0.0:
			GameState.add_resource(cid, rate * delta)

# ---- апгрейды разгона (за крипту) ----
static func upg_owned(id: String) -> bool:
	return GameState.mining_upgrades.has(id)

static func upg_can_buy(id: String) -> bool:
	var d := MiningDB.get_upgrade(id)
	if d.is_empty() or upg_owned(id): return false
	for p in d.get("requires", []):
		if not upg_owned(p): return false
	for res in d.get("cost", {}):
		if GameState.get_resource(res) < float(d["cost"][res]): return false
	return true

static func upg_buy(id: String) -> bool:
	if not upg_can_buy(id): return false
	var d := MiningDB.get_upgrade(id)
	for res in d.get("cost", {}):
		GameState.add_resource(res, -float(d["cost"][res]))
	GameState.mining_upgrades[id] = true
	Events.mining_upgrade_bought.emit(id)
	return true
