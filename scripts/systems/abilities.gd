class_name Abilities

static var _dirty := true
static var _prod_mult: Dictionary = {}
static var _energy_bonus := 0.0

static func mark_dirty() -> void:
	_dirty = true

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
	mark_dirty()
	Events.ability_activated.emit(id)
	return true

static func update(delta: float) -> void:
	for id in GameState.active_abilities.keys():
		GameState.active_abilities[id] = float(GameState.active_abilities[id]) - delta
		if GameState.active_abilities[id] <= 0.0:
			GameState.active_abilities.erase(id)
			GameState.ability_cooldowns[id] = float(AbilitiesDB.get_def(id)["cooldown"])
			mark_dirty()
	for id in GameState.ability_cooldowns.keys():
		GameState.ability_cooldowns[id] = float(GameState.ability_cooldowns[id]) - delta
		if GameState.ability_cooldowns[id] <= 0.0:
			GameState.ability_cooldowns.erase(id)

# ---- вклад активных бафов в движок ----
static func _rebuild_cache() -> void:
	_prod_mult.clear()
	_energy_bonus = 0.0
	for id in GameState.active_abilities:
		var eff: Dictionary = AbilitiesDB.get_def(id).get("effect", {})
		for res in eff.get("mult_production", {}):
			_prod_mult[res] = float(_prod_mult.get(res, 1.0)) * float(eff["mult_production"][res])
		_energy_bonus += float(eff.get("energy_add", 0.0))
	_dirty = false

static func get_production_mult(resource: String) -> float:
	if _dirty: _rebuild_cache()
	return float(_prod_mult.get(resource, 1.0))

static func get_energy_bonus() -> float:
	if _dirty: _rebuild_cache()
	return _energy_bonus
