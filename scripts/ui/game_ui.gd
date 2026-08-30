extends CanvasLayer
class_name GameUI

signal play_requested
signal quit_requested
signal resume_requested
signal restart_requested
signal main_menu_requested

const HUD_MARGIN := 10.0
const MENU_BUTTON_SIZE := Vector2(180, 34)
const MENU_BUTTON_X := 230.0
const OVERLAY_COLOR := Color(0.015, 0.025, 0.035, 0.93)
const DIALOGUE_DURATION := 5.5

var title_label: Label
var objective_label: Label
var prompt_label: Label
var dialogue_panel: ColorRect
var dialogue_label: Label
var transition_label: Label
var utility_label: Label
var title_screen: Control
var controls_screen: Control
var pause_screen: Control
var play_button: Button
var resume_button: Button
var music_control: MusicControl
var dialogue_request := 0
var transition_request := 0

func _ready() -> void:
	layer = 5
	process_mode = Node.PROCESS_MODE_ALWAYS
	build_hud()
	build_title_screen()
	build_pause_screen()

	music_control = MusicControl.new()
	add_child(music_control)

func show_title() -> void:
	title_screen.visible = true
	controls_screen.visible = false
	pause_screen.visible = false
	set_hud_visible(false)
	hide_dialogue()
	hide_transition()

	if music_control != null:
		music_control.visible = false
		music_control.stop_music()

	play_button.grab_focus()

func show_game_hud() -> void:
	title_screen.visible = false
	controls_screen.visible = false
	set_hud_visible(true)
	utility_label.text = "R — RESTART LEVEL   ESC — PAUSE"

	if music_control != null:
		music_control.visible = true
		music_control.start_music()

func show_pause() -> void:
	pause_screen.visible = true
	resume_button.grab_focus()

func hide_pause() -> void:
	pause_screen.visible = false

func set_header(text: String) -> void:
	title_label.text = text

func set_objective(text: String) -> void:
	objective_label.text = "OBJECTIVE: " + text

func set_interaction_prompt(text: String) -> void:
	prompt_label.text = text
	prompt_label.visible = not text.is_empty()

func show_dialogue(text: String) -> void:
	dialogue_request += 1
	var request := dialogue_request
	dialogue_label.text = text
	dialogue_panel.visible = true
	get_tree().create_timer(DIALOGUE_DURATION).timeout.connect(func():
		if request == dialogue_request:
			hide_dialogue()
	)

func hide_dialogue() -> void:
	dialogue_request += 1
	dialogue_panel.visible = false

func show_transition(text: String, seconds: float) -> void:
	transition_request += 1
	var request := transition_request
	transition_label.text = text
	transition_label.visible = true
	get_tree().create_timer(seconds).timeout.connect(func():
		if request == transition_request:
			hide_transition()
	)

func hide_transition() -> void:
	transition_request += 1
	transition_label.visible = false

func show_ending() -> void:
	utility_label.text = "R — MAIN MENU"
	transition_label.text = "YOU FINALLY ESCAPED.\n\nDid you?\n\n[R] MAIN MENU"
	transition_label.visible = true
	set_interaction_prompt("")

func show_controls() -> void:
	title_screen.visible = false
	controls_screen.visible = true

func hide_controls() -> void:
	controls_screen.visible = false
	title_screen.visible = true
	play_button.grab_focus()

func build_hud() -> void:
	var hud := ColorRect.new()
	hud.position = Vector2(HUD_MARGIN, HUD_MARGIN)
	hud.size = Vector2(315, 48)
	hud.color = Color(0.025, 0.04, 0.05, 0.85)
	add_child(hud)
	title_label = make_label(Vector2(20, 14), Vector2(295, 17), 12, Color("a9c2c9"))
	objective_label = make_label(Vector2(20, 30), Vector2(295, 23), 12, Color("eef4e8"))
	var movement_hint := make_label(Vector2(500, 14), Vector2(130, 18), 11, Color("a9c2c9"))
	movement_hint.text = "WASD — MOVE"
	movement_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	utility_label = make_label(Vector2(350, 336), Vector2(280, 16), 10, Color("91adb0"))
	utility_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	prompt_label = make_label(Vector2(170, 329), Vector2(300, 21), 11, Color("f2d47c"))
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialogue_panel = ColorRect.new()
	dialogue_panel.position = Vector2(12, 266)
	dialogue_panel.size = Vector2(616, 55)
	dialogue_panel.color = Color(0.025, 0.04, 0.05, 0.94)
	dialogue_panel.visible = false
	add_child(dialogue_panel)
	dialogue_label = make_label(Vector2(12, 8), Vector2(592, 42), 12, Color("e5ecec"), dialogue_panel)
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	transition_label = make_label(Vector2(60, 130), Vector2(520, 100), 27, Color("f1f4e8"))
	transition_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	transition_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	transition_label.visible = false

func build_title_screen() -> void:
	title_screen = make_overlay()
	var game_title := make_label(Vector2(210, 78), Vector2(220, 54), 42, Color("e8eee5"), title_screen)
	game_title.text = "TRUST"
	game_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	play_button = make_menu_button("PLAY", 165, title_screen, func(): play_requested.emit())
	make_menu_button("CONTROLS", 207, title_screen, show_controls)
	make_menu_button("QUIT", 249, title_screen, func(): quit_requested.emit())
	controls_screen = make_overlay()
	var controls_title := make_label(Vector2(190, 110), Vector2(260, 34), 24, Color.WHITE, controls_screen)
	controls_title.text = "CONTROLS"
	controls_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var controls_text := make_label(Vector2(190, 155), Vector2(260, 55), 16, Color("d7e3e4"), controls_screen)
	controls_text.text = "WASD — MOVE\nE — INTERACT"
	controls_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	make_menu_button("BACK", 240, controls_screen, hide_controls)
	controls_screen.visible = false

func build_pause_screen() -> void:
	pause_screen = make_overlay()
	var pause_title := make_label(Vector2(205, 95), Vector2(230, 38), 27, Color.WHITE, pause_screen)
	pause_title.text = "PAUSED"
	pause_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	resume_button = make_menu_button("RESUME", 150, pause_screen, func(): resume_requested.emit())
	make_menu_button("RESTART LEVEL", 192, pause_screen, func(): restart_requested.emit())
	make_menu_button("MAIN MENU", 234, pause_screen, func(): main_menu_requested.emit())
	pause_screen.visible = false

func make_overlay() -> Control:
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = OVERLAY_COLOR
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(shade)
	return overlay

func make_menu_button(text: String, y_position: float, parent: Control, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.position = Vector2(MENU_BUTTON_X, y_position)
	button.size = MENU_BUTTON_SIZE
	button.add_theme_font_size_override("font_size", 15)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func make_label(position: Vector2, size: Vector2, font_size: int, color: Color, parent: Node = null) -> Label:
	var target_parent: Node = parent if parent != null else self
	var label := Label.new()
	label.position = position
	label.size = size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	target_parent.add_child(label)
	return label

func set_hud_visible(visible: bool) -> void:
	title_label.visible = visible
	objective_label.visible = visible
	utility_label.visible = visible
	prompt_label.visible = false
