class_name Corruption

const ACCRUAL_K := 0.0002      # рост на единицу суммарной скорости в сек (тюнится)
const BONUS := 0.5             # до +50% производства при коррупции = 1.0
const PURGE_AMOUNT := 0.25      # сколько снимает одна стабилизация
const THRESHOLD_VOID := 0.5

static func update(delta: float) -> void:
	var intensity := 0.0
	for res in GameState.production_rates:
		intensity += float(GameState.production_rates[res])
	GameState.corruption = clampf(GameState.corruption + ACCRUAL_K * intensity * delta, 0.0, 1.0)
	if GameState.corruption >= THRESHOLD_VOID and not GameState.flags.get("void_detected", false):
		GameState.flags["void_detected"] = true
		Events.log_message.emit("> [СЕКТОР ??] ОБНАРУЖЕНА НЕИЗВЕСТНАЯ СУЩНОСТЬ", "alert")

static func get_production_bonus_mult() -> float:
	return 1.0 + BONUS * GameState.corruption

static func purge_cost() -> float:
	return 50.0 + 500.0 * GameState.corruption   # дороже при высокой коррупции (тюнится)

static func can_purge() -> bool:
	return GameState.corruption > 0.0 and GameState.get_resource("compute") >= purge_cost()

static func purge() -> bool:
	if not can_purge():
		return false
	GameState.add_resource("compute", -purge_cost())
	GameState.corruption = maxf(0.0, GameState.corruption - PURGE_AMOUNT)
	Events.log_message.emit("> СТАБИЛИЗАЦИЯ: ЦЕЛОСТНОСТЬ ВОССТАНОВЛЕНА", "sys")
	return true
