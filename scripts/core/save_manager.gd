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
	if data.has("research"): GameState.research = data["research"]
	if data.has("corruption"): GameState.corruption = float(data["corruption"])
	if data.has("flags"): GameState.flags = data["flags"]
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

func wipe() -> void:
	var dir := DirAccess.open("user://")
	if dir and dir.file_exists("savegame.json"):
		dir.remove("savegame.json")
	GameState.reset_to_default()
	get_tree().reload_current_scene()
