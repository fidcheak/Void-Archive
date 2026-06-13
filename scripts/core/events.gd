extends Node

signal resource_changed(id: String, value: float)
signal data_gained(amount: float)
signal log_message(text: String, type: String)
signal tick(delta: float)
signal game_loaded()
signal building_purchased(id: String, count: int)
signal research_completed(id: String)
signal anomaly_started(id: String)
signal anomaly_ended(id: String)
