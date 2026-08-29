extends Area2D
class_name Interactable

const INTERACTION_RADIUS := 34.0
const LABEL_MIN_WIDTH := 72.0
const LABEL_WIDTH_PER_CHARACTER := 6.4

var interaction_id: String = ""
var display_name: String = ""
var interaction_text: String = ""

func configure(id: String, title: String, text: String, color: Color, object_size: Vector2 = Vector2(26, 26)) -> void:
	interaction_id = id
	display_name = title
	interaction_text = text
	monitoring = false
	monitorable = false
	add_placeholder_visual(title, color, object_size)

func is_in_range(player_position: Vector2) -> bool:
	return global_position.distance_to(player_position) <= INTERACTION_RADIUS

func add_placeholder_visual(title: String, color: Color, object_size: Vector2) -> void:
	var visual := Polygon2D.new()
	visual.polygon = PackedVector2Array([
		Vector2(-object_size.x / 2.0, -object_size.y / 2.0),
		Vector2(object_size.x / 2.0, -object_size.y / 2.0),
		Vector2(object_size.x / 2.0, object_size.y / 2.0),
		Vector2(-object_size.x / 2.0, object_size.y / 2.0),
	])
	visual.color = color
	add_child(visual)
	var label := Label.new()
	label.text = title
	var label_width := maxf(LABEL_MIN_WIDTH, title.length() * LABEL_WIDTH_PER_CHARACTER)
	label.position = Vector2(-label_width / 2.0, object_size.y / 2.0 + 3.0)
	label.size = Vector2(label_width, 18)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 9)
	label.add_theme_color_override("font_color", Color("d9e5e7"))
	add_child(label)
