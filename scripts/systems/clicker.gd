class_name Clicker

const BASE_CLICK := 1.0
const CLICK_FRACTION := 0.5       # доля суммарного производства за клик
const CP_PER_LEVEL := 0.5         # +50% силы клика за уровень
const CP_BASE_COST := 50.0
const CP_COST_MULT := 1.5
const AC_BASE_COST := 200.0
const AC_COST_MULT := 1.6
const AC_RATE := 1.0              # кликов/сек на уровень автокликера
const AUTO_FRACTION := 0.05       # доля суммарного производства за АВТОклик (ручной клик — 0.5)
const COMBO_STEP := 0.2           # +0.2 множителя за стак
const COMBO_MAX_STACKS := 10.0    # → ×3 макс
const COMBO_DECAY := 4.0          # стаков/сек распада
const COMBO_WINDOW := 1.0         # сек удержания до распада

static func _level_bonus() -> float:
	return 1.0 + CP_PER_LEVEL * float(GameState.click_power_level)

static func combo_mult() -> float:
	return 1.0 + COMBO_STEP * GameState.combo_stacks

static func _total_production() -> float:
	var p := 0.0
	for res in GameState.production_rates:
		p += float(GameState.production_rates[res])
	return p

static func base_click_power() -> float:
	# без производственной доли и без комбо — для автокликера
	return BASE_CLICK * _level_bonus() * Prestige.click_mult()

static func click_power() -> float:
	# ручной клик: база + доля производства, ×уровни ×престиж ×комбо
	return (BASE_CLICK + CLICK_FRACTION * _total_production()) * _level_bonus() * Prestige.click_mult() * combo_mult()

static func autoclick_power() -> float:
	# сила одного автоклика: база + малая доля производства, ×уровни ×престиж, без комбо
	return (BASE_CLICK + AUTO_FRACTION * _total_production()) * _level_bonus() * Prestige.click_mult()

static func autoclick_income() -> float:
	return autoclick_power() * autoclick_rate()

static func do_click() -> float:
	var amt := click_power()
	GameState.add_resource("data", amt)
	GameState.combo_stacks = minf(COMBO_MAX_STACKS, GameState.combo_stacks + 1.0)
	GameState.combo_timer = COMBO_WINDOW
	return amt

static func autoclick_rate() -> float:
	return float(GameState.autoclick_level) * AC_RATE

static var _vis_clicks := 0.0
const MAX_VIS_RATE := 12.0   # максимум всплывающих авто-чисел в секунду

static func update(delta: float) -> void:
	var rate := autoclick_rate()
	if rate > 0.0:
		GameState.add_resource("data", autoclick_income() * delta)   # доход плавный
		# визуал: эмитим числа силой ЗА КЛИК, но не чаще MAX_VIS_RATE/сек (на высоких ур. — выборка)
		_vis_clicks += minf(rate, MAX_VIS_RATE) * delta
		while _vis_clicks >= 1.0:
			_vis_clicks -= 1.0
			Events.click_performed.emit(autoclick_power(), true)
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
