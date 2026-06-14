class_name Clicker

const BASE_CLICK := 1.0
const CLICK_FRACTION := 0.5       # доля суммарного производства за клик
const CP_PER_LEVEL := 0.5         # +50% силы клика за уровень
const CP_BASE_COST := 50.0
const CP_COST_MULT := 1.5
const AC_BASE_COST := 200.0
const AC_COST_MULT := 1.6
const AC_RATE := 1.0              # кликов/сек на уровень автокликера
const COMBO_STEP := 0.2           # +0.2 множителя за стак
const COMBO_MAX_STACKS := 10.0    # → ×3 макс
const COMBO_DECAY := 4.0          # стаков/сек распада
const COMBO_WINDOW := 1.0         # сек удержания до распада

static func _level_bonus() -> float:
	return 1.0 + CP_PER_LEVEL * float(GameState.click_power_level)

static func combo_mult() -> float:
	return 1.0 + COMBO_STEP * GameState.combo_stacks

static func base_click_power() -> float:
	# без производственной доли и без комбо — для автокликера
	return BASE_CLICK * _level_bonus() * Prestige.click_mult()

static func click_power() -> float:
	# ручной клик: база + доля производства, ×уровни ×престиж ×комбо
	var prod := 0.0
	for res in GameState.production_rates:
		prod += float(GameState.production_rates[res])
	return (BASE_CLICK + CLICK_FRACTION * prod) * _level_bonus() * Prestige.click_mult() * combo_mult()

static func do_click() -> void:
	GameState.add_resource("data", click_power())
	GameState.combo_stacks = minf(COMBO_MAX_STACKS, GameState.combo_stacks + 1.0)
	GameState.combo_timer = COMBO_WINDOW

static func autoclick_rate() -> float:
	return float(GameState.autoclick_level) * AC_RATE

static func update(delta: float) -> void:
	var ac := autoclick_rate()
	if ac > 0.0:
		GameState.add_resource("data", base_click_power() * ac * delta)
	if GameState.combo_timer > 0.0:
		GameState.combo_timer -= delta
	elif GameState.combo_stacks > 0.0:
		GameState.combo_stacks = maxf(0.0, GameState.combo_stacks - COMBO_DECAY * delta)

# ---- апгрейды (растущая цена, за Данные) ----
static func click_power_cost() -> float:
	return CP_BASE_COST * pow(CP_COST_MULT, GameState.click_power_level)

static func can_upgrade_click_power() -> bool:
	return GameState.get_resource("data") >= click_power_cost()

static func upgrade_click_power() -> bool:
	if not can_upgrade_click_power(): return false
	GameState.add_resource("data", -click_power_cost())
	GameState.click_power_level += 1
	return true

static func autoclick_cost() -> float:
	return AC_BASE_COST * pow(AC_COST_MULT, GameState.autoclick_level)

static func can_upgrade_autoclick() -> bool:
	return GameState.get_resource("data") >= autoclick_cost()

static func upgrade_autoclick() -> bool:
	if not can_upgrade_autoclick(): return false
	GameState.add_resource("data", -autoclick_cost())
	GameState.autoclick_level += 1
	return true
