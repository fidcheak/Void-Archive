class_name Prestige

const ECHO_SCALE := 10000.0   # данных для 1 эхо (тюнится)
const CORRUPT_ECHO_BONUS := 0.5

static var _dirty := true
static var _prod_mult := 1.0
static var _echo_gain_mult := 1.0
static var _click_mult := 1.0

static func mark_dirty() -> void:
	_dirty = true

# ---- эхо ----
static func echo_gain() -> float:
	if GameState.run_best_data < ECHO_SCALE:
		return 0.0
	var base := sqrt(GameState.run_best_data / ECHO_SCALE)
	base *= (1.0 + CORRUPT_ECHO_BONUS * GameState.run_peak_corruption)
	base *= get_echo_gain_mult()
	return floor(base)

static func can_prestige() -> bool:
	return echo_gain() >= 1.0

static func do_prestige() -> void:
	if not can_prestige():
		return
	var gained := echo_gain()
	GameState.chrono_echo += gained
	GameState.prestige_count += 1
	_reset_run()
	_apply_head_start()
	Events.prestige_done.emit(gained)
	Events.resource_changed.emit("data", GameState.get_resource("data"))
	Events.log_message.emit("> ВРЕМЕННАЯ ЛИНИЯ СВЕРНУТА. ЭХО: +%d" % int(gained), "alert")

static func _reset_run() -> void:
	GameState.resources = { "data": 0.0, "compute": 0.0 }
	GameState.buildings = {}
	GameState.research = {}
	GameState.corruption = 0.0
	GameState.flags = {}
	GameState.active_anomaly = {}
	GameState.anomaly_cooldown = 0.0
	GameState.run_best_data = 0.0
	GameState.run_peak_corruption = 0.0
	Research.mark_dirty()

	# сброс крипто-фермы (флаг crypto_unlocked и мета-прогресс не трогаем)
	GameState.crypto_rigs = {}
	GameState.mining_upgrades = {}
	Mining.mining_ratio = 1.0
	for c in CryptoDB.get_list():
		GameState.resources[c["id"]] = 0.0
		Events.resource_changed.emit(c["id"], 0.0)

static func _apply_head_start() -> void:
	for id in GameState.meta_upgrades:
		var eff: Dictionary = MetaDB.get_def(id).get("effects", {})
		if eff.has("start_data"):
			GameState.add_resource("data", float(eff["start_data"]))

# ---- покупка перков ----
static func is_owned(id: String) -> bool:
	return GameState.meta_upgrades.has(id)

static func prereqs_met(id: String) -> bool:
	for p in MetaDB.get_def(id).get("requires", []):
		if not is_owned(p):
			return false
	return true

static func can_buy(id: String) -> bool:
	return (not is_owned(id)) and prereqs_met(id) and GameState.chrono_echo >= float(MetaDB.get_def(id).get("cost", INF))

static func buy(id: String) -> bool:
	if not can_buy(id):
		return false
	GameState.chrono_echo -= float(MetaDB.get_def(id)["cost"])
	GameState.meta_upgrades[id] = true
	mark_dirty()
	Events.meta_upgrade_bought.emit(id)
	return true

# ---- эффекты для движка ----
static func _rebuild_cache() -> void:
	_prod_mult = 1.0
	_echo_gain_mult = 1.0
	_click_mult = 1.0
	for id in GameState.meta_upgrades:
		var eff: Dictionary = MetaDB.get_def(id).get("effects", {})
		_prod_mult *= float(eff.get("mult_production", 1.0))
		_echo_gain_mult *= float(eff.get("echo_gain_mult", 1.0))
		_click_mult *= float(eff.get("click_mult", 1.0))
	_dirty = false

static func get_production_mult() -> float:
	if _dirty: _rebuild_cache()
	return _prod_mult

static func get_echo_gain_mult() -> float:
	if _dirty: _rebuild_cache()
	return _echo_gain_mult

static func click_mult() -> float:
	if _dirty: _rebuild_cache()
	return _click_mult
