extends Node

const SAVE_PATH := "user://savegame.json"
const MAX_OFFLINE_SECONDS := 8.0 * 3600.0

func save_game() -> void:
	GameState.meta["last_saved"] = Time.get_unix_time_from_system()
	var payload := {
		"resources": GameState.resources,
		"buildings": GameState.buildings,
		"meta": GameState.meta,
		"research": GameState.research,
		"corruption": GameState.corruption,
		"flags": GameState.flags,
		"chrono_echo": GameState.chrono_echo,
		"meta_upgrades": GameState.meta_upgrades,
		"prestige_count": GameState.prestige_count,
		"run_best_data": GameState.run_best_data,
		"run_peak_corruption": GameState.run_peak_corruption,
		"crypto_rigs": GameState.crypto_rigs,
		"mining_upgrades": GameState.mining_upgrades,
		"click_power_level": GameState.click_power_level,
		"autoclick_level": GameState.autoclick_level,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(payload))
		f.close()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f:
		return
	var text := f.get_as_text()
	f.close()
	var data: Variant = JSON.parse_string(text)
	if typeof(data) != TYPE_DICTIONARY:
		return
	if data.has("resources"): GameState.resources = data["resources"]
	if data.has("buildings"): GameState.buildings = data["buildings"]
	if data.has("meta"): GameState.meta = data["meta"]
	if data.has("research"):
		var r := {}
		for k in data["research"]:
			var v = data["research"][k]
			r[k] = (1 if (v is bool and v) else int(v))
		GameState.research = r
	if data.has("corruption"): GameState.corruption = float(data["corruption"])
	if data.has("flags"): GameState.flags = data["flags"]
	if data.has("chrono_echo"): GameState.chrono_echo = float(data["chrono_echo"])
	if data.has("meta_upgrades"): GameState.meta_upgrades = data["meta_upgrades"]
	if data.has("prestige_count"): GameState.prestige_count = int(data["prestige_count"])
	if data.has("run_best_data"): GameState.run_best_data = float(data["run_best_data"])
	if data.has("run_peak_corruption"): GameState.run_peak_corruption = float(data["run_peak_corruption"])
	if data.has("crypto_rigs"): GameState.crypto_rigs = data["crypto_rigs"]
	if data.has("mining_upgrades"): GameState.mining_upgrades = data["mining_upgrades"]
	if data.has("click_power_level"): GameState.click_power_level = int(data["click_power_level"])
	if data.has("autoclick_level"): GameState.autoclick_level = int(data["autoclick_level"])
	Research.mark_dirty()
	Prestige.mark_dirty()
	Abilities.mark_dirty()
	_apply_offline()
	Events.game_loaded.emit()
	Events.resource_changed.emit("data", GameState.get_resource("data"))

func _apply_offline() -> void:
	var last := float(GameState.meta.get("last_saved", 0.0))
	if last <= 0.0:
		return
	var elapsed: float = min(Time.get_unix_time_from_system() - last, MAX_OFFLINE_SECONDS)
	if elapsed <= 0.0:
		return
	var rates := Production.compute_rates()
	for res in rates:
		var rate: float = rates[res]
		if rate != 0.0:
			GameState.add_resource(res, rate * elapsed)
	var crates := Mining.compute_crypto_rates()
	for cid in crates:
		if crates[cid] != 0.0:
			GameState.add_resource(cid, crates[cid] * elapsed)

func wipe() -> void:
	var dir := DirAccess.open("user://")
	if dir and dir.file_exists("savegame.json"):
		dir.remove("savegame.json")
	GameState.reset_to_default()
	get_tree().reload_current_scene()
