extends Node2D
class_name PlaceholderWorld

## Temporary world renderer and collision builder. Level definitions stay in
## Game; this class keeps placeholder-node construction in one place.
const BACKGROUND_COLOR := Color("101820")
const FLOOR_COLOR := Color("22343b")
const WALL_COLOR := Color("3f5962")
const ROOM_LABEL_COLOR := Color("91adb0")
const ROOM_SIZE := Vector2(640, 360)
const BORDER_SIZE := 16.0

func build_background() -> void:
	add_rectangle(Vector2(320, 180), ROOM_SIZE, BACKGROUND_COLOR)
	add_rectangle(Vector2(320, 180), ROOM_SIZE - Vector2(BORDER_SIZE * 2.0, BORDER_SIZE * 2.0), FLOOR_COLOR)

func add_border() -> void:
	add_wall(Vector2(320, BORDER_SIZE / 2.0), Vector2(ROOM_SIZE.x, BORDER_SIZE))
	add_wall(Vector2(320, ROOM_SIZE.y - BORDER_SIZE / 2.0), Vector2(ROOM_SIZE.x, BORDER_SIZE))
	add_wall(Vector2(BORDER_SIZE / 2.0, 180), Vector2(BORDER_SIZE, ROOM_SIZE.y))
	add_wall(Vector2(ROOM_SIZE.x - BORDER_SIZE / 2.0, 180), Vector2(BORDER_SIZE, ROOM_SIZE.y))

func add_wall(position: Vector2, dimensions: Vector2, color: Color = WALL_COLOR) -> void:
	var body := StaticBody2D.new()
	body.position = position
	add_child(body)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = dimensions
	collision.shape = shape
	body.add_child(collision)
	add_rectangle(Vector2.ZERO, dimensions, color, body)

func add_furniture(position: Vector2, dimensions: Vector2, color: Color) -> void:
	add_wall(position, dimensions, color)

func add_interactable(id: String, title: String, text: String, position: Vector2, color: Color, dimensions: Vector2) -> void:
	var item := Interactable.new()
	item.configure(id, title, text, color, dimensions)
	item.position = position
	add_child(item)

func add_room_label(text: String, position: Vector2) -> void:
	var label := Label.new()
	label.text = text
	label.position = position
	label.size = Vector2(175, 20)
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", ROOM_LABEL_COLOR)
	add_child(label)

func nearest_interactable(player_position: Vector2) -> Interactable:
	var nearest: Interactable = null
	var nearest_distance: float = INF
	for child in get_children():
		var item: Interactable = child as Interactable
		if item == null or not item.is_in_range(player_position):
			continue
		var distance: float = item.global_position.distance_to(player_position)
		if distance < nearest_distance:
			nearest = item
			nearest_distance = distance
	return nearest

func add_rectangle(position: Vector2, dimensions: Vector2, color: Color, parent: Node = null) -> void:
	var target_parent: Node = parent if parent != null else self
	var visual := Polygon2D.new()
	visual.position = position
	visual.polygon = PackedVector2Array([
		Vector2(-dimensions.x / 2.0, -dimensions.y / 2.0),
		Vector2(dimensions.x / 2.0, -dimensions.y / 2.0),
		Vector2(dimensions.x / 2.0, dimensions.y / 2.0),
		Vector2(-dimensions.x / 2.0, dimensions.y / 2.0),
	])
	visual.color = color
	target_parent.add_child(visual)
