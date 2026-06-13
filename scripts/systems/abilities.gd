class_name Abilities

static func is_unlocked(id: String) -> bool:
	return Research.is_owned(String(AbilitiesDB.get_def(id).get("unlocked_by", "")))

static func is_active(id: String) -> bool:
	return GameState.active_abilities.has(id)

static func cooldown_left(id: String) -> float:
	return float(GameState.ability_cooldowns.get(id, 0.0))

static func is_ready(id: String) -> bool:
	return is_unlocked(id) and not is_active(id) and cooldown_left(id) <= 0.0

static func activate(id: String) -> bool:
	if not is_ready(id):
		return false
	GameState.active_abilities[id] = float(AbilitiesDB.get_def(id)["duration"])
	Events.ability_activated.emit(id)
	return true

static func update(delta: float) -> void:
	for id in GameState.active_abilities.keys():
		GameState.active_abilities[id] = float(GameState.active_abilities[id]) - delta
		if GameState.active_abilities[id] <= 0.0:
			GameState.active_abilities.erase(id)
			GameState.ability_cooldowns[id] = float(AbilitiesDB.get_def(id)["cooldown"])
	for id in GameState.ability_cooldowns.keys():
		GameState.ability_cooldowns[id] = float(GameState.ability_cooldowns[id]) - delta
		if GameState.ability_cooldowns[id] <= 0.0:
			GameState.ability_cooldowns.erase(id)

# ---- вклад активных бафов в движок ----
static func get_production_mult(resource: String) -> float:
	var m := 1.0
	for id in GameState.active_abilities:
		var mp: Dictionary = AbilitiesDB.get_def(id).get("effect", {}).get("mult_production", {})
		if mp.has(resource):
			m *= float(mp[resource])
	return m

static func get_energy_bonus() -> float:
	var b := 0.0
	for id in GameState.active_abilities:
		b += float(AbilitiesDB.get_def(id).get("effect", {}).get("energy_add", 0.0))
	return b
