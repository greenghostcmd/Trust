extends Control
class_name MusicControl


const MUSIC_PATH := "res://assets/audio/music.wav"
const REQUIRED_PRESSES := 4

const ACTIVE_SEGMENT_COLOR := Color("e1c86b")
const INACTIVE_SEGMENT_COLOR := Color("34464b")
const BUTTON_COLOR := Color("17272c")
const BUTTON_HOVER_COLOR := Color("294149")
const TEXT_COLOR := Color("d9e5e7")

var music_player: AudioStreamPlayer
var mute_button: Button
var progress_bar: HBoxContainer
var status_label: Label
var segments: Array[ColorRect] = []

var press_count := 0
var is_muted := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	build_music_control()
	build_music_player()


func build_music_player() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.volume_db = -4.0
	add_child(music_player)

	var music_stream := load(MUSIC_PATH) as AudioStream

	if music_stream == null:
		push_error("Could not load music file: " + MUSIC_PATH)
		return

	music_player.stream = music_stream

	if music_stream is AudioStreamOggVorbis:
		var ogg_stream := music_stream as AudioStreamOggVorbis
		ogg_stream.loop = true


func build_music_control() -> void:
	status_label = Label.new()
	status_label.position = Vector2(524, 277)
	status_label.size = Vector2(106, 16)
	status_label.text = "AUDIO"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status_label.add_theme_font_size_override("font_size", 9)
	status_label.add_theme_color_override("font_color", Color("91adb0"))
	add_child(status_label)

	progress_bar = HBoxContainer.new()
	progress_bar.position = Vector2(566, 292)
	progress_bar.size = Vector2(56, 8)
	progress_bar.add_theme_constant_override("separation", 3)
	progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(progress_bar)

	for index in range(REQUIRED_PRESSES):
		var segment := ColorRect.new()
		segment.custom_minimum_size = Vector2(11, 5)
		segment.color = INACTIVE_SEGMENT_COLOR
		segment.mouse_filter = Control.MOUSE_FILTER_IGNORE

		progress_bar.add_child(segment)
		segments.append(segment)

	mute_button = Button.new()
	mute_button.position = Vector2(540, 301)
	mute_button.size = Vector2(90, 28)
	mute_button.text = "MUTE"
	mute_button.mouse_filter = Control.MOUSE_FILTER_STOP
	mute_button.add_theme_font_size_override("font_size", 10)
	mute_button.add_theme_color_override("font_color", TEXT_COLOR)

	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = BUTTON_COLOR
	normal_style.border_color = Color("46616a")
	normal_style.set_border_width_all(1)
	normal_style.corner_radius_top_left = 2
	normal_style.corner_radius_top_right = 2
	normal_style.corner_radius_bottom_left = 2
	normal_style.corner_radius_bottom_right = 2

	var hover_style := normal_style.duplicate()
	hover_style.bg_color = BUTTON_HOVER_COLOR

	mute_button.add_theme_stylebox_override("normal", normal_style)
	mute_button.add_theme_stylebox_override("hover", hover_style)
	mute_button.add_theme_stylebox_override("pressed", hover_style)

	mute_button.pressed.connect(_on_mute_button_pressed)

	add_child(mute_button)


func _on_mute_button_pressed() -> void:
	press_count += 1
	update_progress_bar()

	if press_count < REQUIRED_PRESSES:
		return

	press_count = 0
	is_muted = not is_muted

	if music_player != null:
		music_player.stream_paused = is_muted

	if is_muted:
		mute_button.text = "UNMUTE"
		status_label.text = "MUTED"
	else:
		mute_button.text = "MUTE"
		status_label.text = "AUDIO"

	update_progress_bar()


func update_progress_bar() -> void:
	for index in range(segments.size()):
		if index < press_count:
			segments[index].color = ACTIVE_SEGMENT_COLOR
		else:
			segments[index].color = INACTIVE_SEGMENT_COLOR


func start_music() -> void:
	if music_player == null:
		return

	if music_player.stream == null:
		return

	if not music_player.playing:
		music_player.play()

	music_player.stream_paused = is_muted


func stop_music() -> void:
	if music_player != null:
		music_player.stop()