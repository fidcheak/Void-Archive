class_name FloatingText
extends Control

func spawn(text: String, global_pos: Vector2, color: Color = Palette.AMBER) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.modulate = color
	lbl.z_index = 100
	add_child(lbl)
	lbl.global_position = global_pos

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl, "global_position:y", global_pos.y - 50.0, 0.8)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.8).set_ease(Tween.EASE_IN)
	tw.set_parallel(false)
	tw.tween_callback(lbl.queue_free)
