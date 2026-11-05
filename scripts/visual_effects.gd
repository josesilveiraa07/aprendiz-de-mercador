extends CanvasLayer


func add_child_themed(node: Control) -> void:
	node.theme = GameState.ui_theme
	add_child(node)

# Antes era o emoji 🪙, que não aparece em todos os sistemas (ex.: Windows antigo
# e Linux sem fonte de emoji). Agora a moeda é desenhada com a fonte do jogo.
const COIN_GLYPH := "●"
const COIN_COLOR := Color("e0a526")
const COIN_EDGE := Color("7a4a10")


func play_coin_burst(origin: Vector2, count: int = 10) -> void:
	for i in count:
		var coin := Label.new()
		coin.text = COIN_GLYPH
		coin.add_theme_font_size_override("font_size", randi_range(16, 26))
		coin.add_theme_color_override("font_color", COIN_COLOR)
		coin.add_theme_color_override("font_outline_color", COIN_EDGE)
		coin.add_theme_constant_override("outline_size", 6)
		coin.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		coin.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		add_child_themed(coin)

		var start := origin + Vector2(randf_range(-30.0, 30.0), randf_range(-20.0, 10.0))
		coin.position = start

		var fall_distance := randf_range(100.0, 220.0)
		var duration := randf_range(0.7, 1.3)
		var drift := randf_range(-80.0, 80.0)

		var tween := create_tween().set_parallel(true)
		tween.tween_property(coin, "position:y", start.y + fall_distance, duration).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(coin, "position:x", start.x + drift, duration).set_ease(Tween.EASE_OUT)
		tween.tween_property(coin, "rotation", randf_range(-2.0, 2.0), duration)
		tween.tween_property(coin, "modulate:a", 0.0, 0.35).set_delay(duration - 0.35)
		tween.chain().tween_callback(coin.queue_free)


func play_floating_text(origin: Vector2, text: String, color: Color = Color(0.2, 0.85, 0.35)) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.12, 0.06, 0.03))
	label.add_theme_constant_override("outline_size", 6)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child_themed(label)
	label.position = origin - Vector2(80.0, 0.0)

	var tween := create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", origin.y - 70.0, 1.1).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.4).set_delay(0.7)
	tween.chain().tween_callback(label.queue_free)


func flash_panel(panel: Control, color: Color, duration: float = 0.35) -> void:
	if panel == null:
		return

	var overlay := ColorRect.new()
	overlay.color = Color(color.r, color.g, color.b, 0.0)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(overlay)

	var tween := create_tween()
	tween.tween_property(overlay, "color:a", color.a, duration * 0.35)
	tween.tween_property(overlay, "color:a", 0.0, duration * 0.65)
	tween.chain().tween_callback(overlay.queue_free)


func shake_control(control: Control, strength: float = 8.0, duration: float = 0.4) -> void:
	if control == null:
		return

	var original := control.position
	var tween := create_tween()
	var steps := 6
	for i in steps:
		var offset := Vector2(
			randf_range(-strength, strength),
			randf_range(-strength * 0.5, strength * 0.5)
		)
		tween.tween_property(control, "position", original + offset, duration / float(steps))
	tween.tween_property(control, "position", original, duration / float(steps))


func pulse_label(label: Label, scale_factor: float = 1.15, duration: float = 0.3) -> void:
	if label == null:
		return

	var original_scale := label.scale
	var tween := create_tween()
	tween.tween_property(label, "scale", original_scale * scale_factor, duration * 0.45).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", original_scale, duration * 0.55).set_ease(Tween.EASE_IN)


func fade_in_control(control: Control, duration: float = 0.45) -> void:
	if control == null:
		return

	control.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(control, "modulate:a", 1.0, duration).set_ease(Tween.EASE_OUT)


func play_level_up_burst(origin: Vector2) -> void:
	play_coin_burst(origin, 18)
	for i in 6:
		var star := Label.new()
		star.text = "✦"
		star.add_theme_font_size_override("font_size", randi_range(18, 30))
		star.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		add_child_themed(star)
		star.position = origin + Vector2(randf_range(-50.0, 50.0), randf_range(-30.0, 20.0))

		var tween := create_tween().set_parallel(true)
		tween.tween_property(star, "position", star.position + Vector2(randf_range(-40.0, 40.0), randf_range(-90.0, -40.0)), 0.9)
		tween.tween_property(star, "modulate:a", 0.0, 0.35).set_delay(0.55)
		tween.tween_property(star, "scale", Vector2(1.4, 1.4), 0.9)
		tween.chain().tween_callback(star.queue_free)
