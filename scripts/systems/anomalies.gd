class_name Anomalies

const COOLDOWN_MAX := 90.0    # редко при низкой коррупции
const COOLDOWN_MIN := 25.0    # часто при высокой
const COOLDOWN_JITTER := 0.3

static func update(delta: float) -> void:
	if not GameState.active_anomaly.is_empty():
		GameState.active_anomaly["time_left"] = float(GameState.active_anomaly["time_left"]) - delta
		if GameState.active_anomaly["time_left"] <= 0.0:
			_end()
	else:
		GameState.anomaly_cooldown -= delta
		if GameState.anomaly_cooldown <= 0.0:
			_spawn()

static func get_active_production_mult() -> float:
	if GameState.active_anomaly.is_empty():
		return 1.0
	return float(GameState.active_anomaly.get("mult", 1.0))

static func _spawn() -> void:
	var def := _pick_weighted()
	if def.is_empty():
		GameState.anomaly_cooldown = _next_cooldown()
		return
	Events.log_message.emit(String(def.get("msg", "> АНОМАЛИЯ")), ("alert" if def["type"] == "glitch" else "sys"))
	var eff: Dictionary = def.get("effect", {})
	if eff.has("instant_data_seconds"):
		var burst := float(GameState.production_rates.get("data", 0.0)) * float(eff["instant_data_seconds"])
		GameState.add_resource("data", burst)
		GameState.anomaly_cooldown = _next_cooldown()
		Events.anomaly_started.emit(def["id"])
		Events.anomaly_ended.emit(def["id"])   # мгновенная
	else:
		var dur := float(def.get("duration", 30.0))
		GameState.active_anomaly = {
			"id": def["id"], "name": def["name"], "type": def["type"],
			"mult": float(eff.get("mult_production", 1.0)),
			"duration": dur, "time_left": dur,
		}
		Events.anomaly_started.emit(def["id"])

static func _end() -> void:
	var id := String(GameState.active_anomaly.get("id", ""))
	GameState.active_anomaly = {}
	GameState.anomaly_cooldown = _next_cooldown()
	Events.anomaly_ended.emit(id)

static func _next_cooldown() -> float:
	var base := lerpf(COOLDOWN_MAX, COOLDOWN_MIN, GameState.corruption)
	return base * (1.0 + randf_range(-COOLDOWN_JITTER, COOLDOWN_JITTER))

static func _pick_weighted() -> Dictionary:
	var c := GameState.corruption
	var total := 0.0
	var weights := []
	for a in AnomaliesDB.get_list():
		var w := maxf(0.01, float(a["base_weight"]) + float(a["corruption_bias"]) * c)
		weights.append(w)
		total += w
	var roll := randf() * total
	var acc := 0.0
	var list := AnomaliesDB.get_list()
	for i in list.size():
		acc += weights[i]
		if roll <= acc:
			return list[i]
	return list[list.size() - 1]
