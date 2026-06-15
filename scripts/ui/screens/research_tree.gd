class_name ResearchTreeScreen
extends Control

signal back_pressed

const HUB_GAP := 220.0   # отступ от центра до корня ветки
const ROW_STEP := 160.0  # шаг по глубине (вдоль направления ветки)
const SPREAD := 150.0    # разброс сиблингов (поперёк направления)
const BRANCH_DIR := {
	"machines":  Vector2( 1,  0),   # восток
	"cognition": Vector2(-1,  0),   # запад
	"void":      Vector2( 0, -1),   # север
	"energy":    Vector2( 0,  1),   # юг
}

var _graph: TreeGraph
var _compute_label: Label
var _layout: Dictionary = {}   # id -> Vector2 (авто-раскладка по слоям)
var _acc := 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var layout := VBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(layout)

	layout.add_child(_build_header())

	_layout = _compute_layout()

	_graph = TreeGraph.new()
	_graph.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_graph.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_graph.node_provider = _nodes
	_graph.action_handler = _do_action
	layout.add_child(_graph)
	_graph.build()

	Events.research_completed.connect(_on_research_completed)
	Events.tick.connect(_on_tick)
	visibility_changed.connect(_on_visibility_changed)

	_refresh_full()

func _build_header() -> Control:
	var panel := PanelContainer.new()

	var box := HBoxContainer.new()
	panel.add_child(box)

	var back_btn := Button.new()
	back_btn.text = "← НАЗАД"
	back_btn.pressed.connect(func(): back_pressed.emit())
	box.add_child(back_btn)

	var title := Label.new()
	title.text = "ДЕРЕВО ИССЛЕДОВАНИЙ"
	title.add_theme_color_override("font_color", Palette.AMBER)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	var compute_name := Label.new()
	compute_name.text = "%s:" % Labels.res_name("compute").to_upper()
	compute_name.add_theme_color_override("font_color", Palette.COMPUTE)
	box.add_child(compute_name)

	_compute_label = Label.new()
	box.add_child(_compute_label)

	return panel

func _nodes() -> Array:
	var branch_colors := {}
	for b in ResearchDB.get_branches():
		branch_colors[b["id"]] = b["color"]

	# один проход по research: множества owned (id->level) и excluded (id->true),
	# вместо per-node перебора в Research.is_excluded/prereqs_met/is_available
	var owned := {}
	for id in GameState.research:
		var lvl := int(GameState.research[id])
		if lvl >= 1:
			owned[id] = lvl
	var excluded := {}
	for r in ResearchDB.get_list():
		for ex in r.get("excludes", []):
			if owned.has(r["id"]):
				excluded[ex] = true
			if owned.has(ex):
				excluded[r["id"]] = true

	var result := []
	for r in ResearchDB.get_list():
		var id: String = r["id"]
		var lvl := int(owned.get(id, 0))
		var max_lvl := Research.max_level(id)
		var maxed := lvl >= max_lvl
		var is_excl := excluded.has(id)

		var prereqs_ok := true
		for p in r.get("requires", []):
			if not owned.has(p):
				prereqs_ok = false
				break

		var flag := String(r.get("requires_flag", ""))
		var flag_ok := flag == "" or bool(GameState.flags.get(flag, false))

		var state := TreeGraph.NodeState.LOCKED
		if lvl >= 1:
			state = TreeGraph.NodeState.OWNED
		elif not r.get("stub", false) and not is_excl and flag_ok and not maxed and prereqs_ok:
			state = TreeGraph.NodeState.AVAILABLE

		result.append({
			"id": id, "title": r["name"], "desc": String(r.get("desc", "")),
			"pos": _layout.get(id, r["pos"]), "color": branch_colors.get(r["branch"], Palette.TEXT_3),
			"rarity": r.get("rarity", "common"),
			"state": state,
			"level": lvl, "max_level": max_lvl,
			"cost_text": _cost_text(r),
			"effect_text": _effect_text(r),
			"req_text": _req_text(r, is_excl),
			"action_label": "Максимум" if maxed else "Изучить (ур. %d→%d)" % [lvl, lvl + 1],
			"can_act": state == TreeGraph.NodeState.AVAILABLE and Research.can_afford(id),
			"requires": r.get("requires", []),
			"excludes": r.get("excludes", []),
			"blocked_by_choice": is_excl and lvl == 0,
		})
	return result

func _cost_text(r: Dictionary) -> String:
	var cost: Dictionary = Research.next_cost(r["id"])
	if cost.is_empty():
		return "—"
	var parts := PackedStringArray()
	for res_id in cost.keys():
		parts.append("%s %s" % [Format.num(cost[res_id]), Labels.res_short(res_id)])
	return ", ".join(parts)

func _effect_text(r: Dictionary) -> String:
	var eff: Dictionary = r.get("effects", {})
	var max_lvl := Research.max_level(r["id"])
	var suffix := " за ранг" if max_lvl > 1 else ""
	var parts := PackedStringArray()
	parts.append("Уровень: %d / %d" % [Research.level(r["id"]), max_lvl])
	if eff.has("mult_production"):
		var mp: Dictionary = eff["mult_production"]
		for res_id in mp.keys():
			var factor := float(mp[res_id])
			var tag := " (дебафф)" if factor < 1.0 else ""
			parts.append("%s ×%s%s%s" % [Labels.res_name(res_id), Format.num(factor), suffix, tag])
	if eff.has("mult_building"):
		var mb: Dictionary = eff["mult_building"]
		for b_id in mb.keys():
			parts.append("%s ×%s%s" % [_building_name(b_id), Format.num(float(mb[b_id])), suffix])
	if eff.has("add_base_energy"):
		var bonus := float(eff["add_base_energy"])
		var tag := " (дебафф)" if bonus < 0.0 else ""
		parts.append("%+d базовой энергии%s%s" % [int(bonus), suffix, tag])
	var ability := _ability_unlock(r["id"])
	if not ability.is_empty():
		parts.append("Открывает: %s" % String(ability["name"]))
	var building := _building_unlock(r["id"])
	if not building.is_empty():
		parts.append("Открывает постройку: %s" % String(building["name"]))
	return ", ".join(parts)

func _ability_unlock(node_id: String) -> Dictionary:
	for a in AbilitiesDB.get_list():
		if String(a.get("unlocked_by", "")) == node_id:
			return a
	return {}

func _building_unlock(node_id: String) -> Dictionary:
	for b in BuildingsDB.get_list():
		if String(b.get("requires_research", "")) == node_id:
			return b
	return {}

func _req_text(r: Dictionary, is_excl: bool) -> String:
	if is_excl:
		return "Путь закрыт (выбран другой узел)"

	var flag := String(r.get("requires_flag", ""))
	if flag != "" and not GameState.flags.get(flag, false):
		return "Требуется обнаружить повреждённый сектор (целостность < 50%)"

	var names := PackedStringArray()
	for p in r.get("requires", []):
		names.append(String(Research.get_def(p).get("name", p)))
	return ", ".join(names)

func _do_action(id: String) -> bool:
	if not Research.research(id):
		return false
	var rname := String(Research.get_def(id)["name"])
	Events.log_message.emit("> ТЕХНОЛОГИЯ ВНЕДРЕНА: %s" % rname, "sys")
	return true

func _building_name(b_id: String) -> String:
	for b in BuildingsDB.get_list():
		if b["id"] == b_id:
			return String(b["name"])
	return b_id

func _on_research_completed(_id: String) -> void:
	_refresh_full()

func _on_visibility_changed() -> void:
	if visible:
		_refresh_full()

func _refresh_full() -> void:
	if not is_visible_in_tree(): return
	_compute_label.text = Format.num(GameState.get_resource("compute"))
	_graph.refresh()

func _on_tick(delta: float) -> void:
	_acc += delta
	if _acc < 0.1: return
	_acc = 0.0
	if not is_visible_in_tree(): return
	_compute_label.text = Format.num(GameState.get_resource("compute"))
	var sel := _graph.get_selected_id()
	if sel != "":
		_graph.refresh_action_state(Research.can_research(sel))

# ---- авто-раскладка по слоям: глубина -> ряд, барицентр предпосылок -> столбец (Слой D) ----
func _compute_layout() -> Dictionary:
	var by_id := {}
	var by_branch := {}
	for r in ResearchDB.get_list():
		by_id[r["id"]] = r
		var b: String = r["branch"]
		if not by_branch.has(b):
			by_branch[b] = []
		by_branch[b].append(r["id"])

	var result := {}
	for b in by_branch:
		var ids: Array = by_branch[b]
		var dir: Vector2 = BRANCH_DIR.get(b, Vector2(1, 0))
		var perp := Vector2(-dir.y, dir.x)

		# 1) глубина = длина самой длинной цепочки предпосылок внутри ветки
		var depth := {}
		for id in ids:
			_compute_depth(id, b, by_id, depth)

		var max_depth := 0
		var rows := {}
		for id in ids:
			var d: int = depth[id]
			max_depth = maxi(max_depth, d)
			if not rows.has(d):
				rows[d] = []
			rows[d].append(id)

		# 3) горизонталь по барицентру предпосылок, ряд за рядом от корней вверх
		var x := {}
		for d in range(0, max_depth + 1):
			if not rows.has(d):
				continue
			var row: Array = rows[d]

			var prefx := {}
			for id in row:
				var refs := PackedFloat64Array()
				for p in by_id[id].get("requires", []):
					if by_id.has(p) and by_id[p]["branch"] == b and x.has(p):
						refs.append(x[p])
				if refs.is_empty():
					prefx[id] = 0.0   # корни — локальный центр кластера ветки
				else:
					var sum := 0.0
					for v in refs:
						sum += v
					prefx[id] = sum / refs.size()

			row.sort_custom(func(a, c): return prefx[a] < prefx[c])

			var n := row.size()
			var avg_prefx := 0.0
			for id in row:
				avg_prefx += prefx[id]
			avg_prefx /= n

			var span := float(n - 1) * SPREAD
			for i in range(n):
				x[row[i]] = avg_prefx - span * 0.5 + float(i) * SPREAD

		# 4) полировка сверху-вниз: родитель подвинут к среднему x своих детей-в-ветке
		var children := {}
		for id in ids:
			for p in by_id[id].get("requires", []):
				if by_id.has(p) and by_id[p]["branch"] == b:
					if not children.has(p):
						children[p] = []
					children[p].append(id)
		for d in range(max_depth, -1, -1):
			if not rows.has(d):
				continue
			for id in rows[d]:
				if children.has(id):
					var sum := 0.0
					for c in children[id]:
						sum += x[c]
					x[id] = sum / children[id].size()

		# 5) финальная раздвижка: полировка могла свести соседей вместе — гарантируем интервал >= SPREAD
		for d in rows:
			var row: Array = rows[d].duplicate()
			row.sort_custom(func(a, c): return x[a] < x[c])
			for i in range(1, row.size()):
				if x[row[i]] - x[row[i - 1]] < SPREAD:
					x[row[i]] = x[row[i - 1]] + SPREAD

		# 6) итоговые позиции: ось вдоль направления ветки, разброс — поперёк
		for id in ids:
			var d: int = depth[id]
			var axis := HUB_GAP + float(d) * ROW_STEP
			result[id] = dir * axis + perp * x[id]

	return result

func _compute_depth(id: String, branch: String, by_id: Dictionary, depth: Dictionary) -> int:
	if depth.has(id):
		return depth[id]
	var max_d := -1
	for p in by_id[id].get("requires", []):
		if by_id.has(p) and by_id[p]["branch"] == branch:
			max_d = maxi(max_d, _compute_depth(p, branch, by_id, depth))
	depth[id] = max_d + 1
	return depth[id]
