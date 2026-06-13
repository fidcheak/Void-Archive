extends Node

const MAX_DELTA := 0.25
const AUTOSAVE_INTERVAL := 15.0

var current_data_rate := 0.0
var _autosave_timer := 0.0

func _process(delta: float) -> void:
	var dt: float = min(delta, MAX_DELTA)   # кламп от свёрнутой вкладки
	Anomalies.update(dt)
	Production.update(dt)
	Corruption.update(dt)
	GameState.run_best_data = maxf(GameState.run_best_data, GameState.get_resource("data"))
	GameState.run_peak_corruption = maxf(GameState.run_peak_corruption, GameState.corruption)
	Events.tick.emit(dt)
	_autosave_timer += dt
	if _autosave_timer >= AUTOSAVE_INTERVAL:
		_autosave_timer = 0.0
		SaveManager.save_game()
