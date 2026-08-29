extends Area2D
class_name Interactable

const INTERACTION_RADIUS := 34.0
const LABEL_MIN_WIDTH := 72.0
const LABEL_WIDTH_PER_CHARACTER := 6.4

var interaction_id: String = ""
var display_name: String = ""
var interaction_text: String = ""


func configure(
	id: String,
	title: String,
	text: String,
	color: Color,
	object_size: Vector2 = Vector2(26, 26)
) -> void:
	interaction_id = id
	display_name = title
	interaction_text = text
	monitoring = false
	monitorable = false
	add_placeholder_visual(title, color, object_size)


func is_in_range(player_position: Vector2) -> bool:
	return global_position.distance_to(player_position) <= INTERACTION_RADIUS


func add_placeholder_visual(
	title: String,
	color: Color,
	object_size: Vector2
) -> void:
	var texture_path := get_texture_path(title)

	if texture_path != "":
		var sprite := Sprite2D.new()
		var texture := load(texture_path) as Texture2D

		if texture != null:
			sprite.texture = texture
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.scale = get_sprite_scale(texture, object_size)
			add_child(sprite)
	else:
		var visual := Polygon2D.new()
		visual.polygon = PackedVector2Array([
			Vector2(-object_size.x / 2.0, -object_size.y / 2.0),
			Vector2(object_size.x / 2.0, -object_size.y / 2.0),
			Vector2(object_size.x / 2.0, object_size.y / 2.0),
			Vector2(-object_size.x / 2.0, object_size.y / 2.0)
		])
		visual.color = color
		add_child(visual)

	var label := Label.new()
	label.text = title

	var label_width := maxf(
		LABEL_MIN_WIDTH,
		title.length() * LABEL_WIDTH_PER_CHARACTER
	)

	label.position = Vector2(
		-label_width / 2.0,
		object_size.y / 2.0 + 3.0
	)

	label.size = Vector2(label_width, 18)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_color_override("font_color", Color("d9e5e7"))
	add_child(label)


func get_texture_path(title: String) -> String:
	match title:
		"CLOCK":
			return "res://assets/sprites/clock.png"
		"LANTERN":
			return "res://assets/sprites/lantern.png"
		"RECORD CASE":
			return "res://assets/sprites/record_case.png"
		"EXIT":
			return "res://assets/sprites/exit_door.png"
		"ARCHIVE":
			return "res://assets/sprites/archive_door.png"
		"TRUST":
			return "res://assets/sprites/trust_door.png"
		"SERVICE":
			return "res://assets/sprites/service_panel.png"
		"SIGN":
			return "res://assets/sprites/exit_sign.png"
		_:
			return ""


func get_sprite_scale(texture: Texture2D, object_size: Vector2) -> Vector2:
	var texture_size := texture.get_size()

	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return Vector2.ONE

	var scale_x := object_size.x / texture_size.x
	var scale_y := object_size.y / texture_size.y
	var uniform_scale := minf(scale_x, scale_y)

	return Vector2(uniform_scale, uniform_scale)