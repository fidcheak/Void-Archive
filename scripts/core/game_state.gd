extends Node

var resources := { "data": 0.0, "compute": 0.0 }
var buildings := {}                   # id -> count (пусто)
var crypto_rigs := {}          # rig_id -> count — СОХРАНЯЕТСЯ
var mining_upgrades := {}      # id -> true — СОХРАНЯЕТСЯ
var meta := { "version": 0, "last_saved": 0.0, "total_clicks": 0 }
var research := {}            # id -> true (изученные узлы) — СОХРАНЯЕТСЯ
var corruption := 0.0         # 0..1, нестабильность — СОХРАНЯЕТСЯ
var flags := {}                # вехи (id -> true) — СОХРАНЯЕТСЯ

# Аномалии — производные/транзиентные поля, не сохраняются
var active_anomaly := {}       # {} если нет; иначе {id,name,type,mult,duration,time_left}
var anomaly_cooldown := 0.0    # сек до следующей аномалии

# Активные способности — транзиентные поля, не сохраняются
var active_abilities := {}     # id -> остаток времени бафа
var ability_cooldowns := {}    # id -> остаток кулдауна

# Мета (переживает престиж) — СОХРАНЯЕТСЯ
var chrono_echo := 0.0
var meta_upgrades := {}        # id -> true
var prestige_count := 0

# Трекинг забега (для формулы эхо) — СОХРАНЯЕТСЯ, сбрасывается престижем
var run_best_data := 0.0
var run_peak_corruption := 0.0

# Энергосеть — производные поля, не сохраняются, пересчитываются Production.recompute()
var energy_production := 0.0
var energy_demand := 0.0
var power_ratio := 1.0
var production_rates := {}    # resource -> rate (производное, НЕ сохраняется)

func _init() -> void:
	for cid in CryptoDB.ids():
		resources[cid] = 0.0

func get_resource(id: String) -> float:
	return float(resources.get(id, 0.0))

func add_resource(id: String, amount: float) -> void:
	resources[id] = get_resource(id) + amount
	Events.resource_changed.emit(id, resources[id])

func reset_to_default() -> void:
	resources = { "data": 0.0, "compute": 0.0 }
	for cid in CryptoDB.ids():
		resources[cid] = 0.0
	buildings = {}
	crypto_rigs = {}
	mining_upgrades = {}
	meta = { "version": 0, "last_saved": 0.0, "total_clicks": 0 }
	research = {}
	corruption = 0.0
	flags = {}
	active_anomaly = {}
	anomaly_cooldown = 0.0
	active_abilities = {}
	ability_cooldowns = {}
	chrono_echo = 0.0
	meta_upgrades = {}
	prestige_count = 0
	run_best_data = 0.0
	run_peak_corruption = 0.0
