class_name Prestige

const ECHO_SCALE := 10000.0   # данных для 1 эхо (тюнится)
const CORRUPT_ECHO_BONUS := 0.5

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
	Events.meta_upgrade_bought.emit(id)
	return true

# ---- эффекты для движка ----
static func get_production_mult() -> float:
	var m := 1.0
	for id in GameState.meta_upgrades:
		m *= float(MetaDB.get_def(id).get("effects", {}).get("mult_production", 1.0))
	return m

static func get_echo_gain_mult() -> float:
	var m := 1.0
	for id in GameState.meta_upgrades:
		m *= float(MetaDB.get_def(id).get("effects", {}).get("echo_gain_mult", 1.0))
	return m

static func click_value() -> float:
	return 1.0

static func autoclick_rate() -> float:
	for id in GameState.meta_upgrades:
		if bool(MetaDB.get_def(id).get("effects", {}).get("autoclick", false)):
			return click_value()   # клик/сек эквивалент
	return 0.0
