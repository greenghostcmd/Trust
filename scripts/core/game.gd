extends Node2D

const LEVEL_1 := 1
const LEVEL_2 := 2
const LEVEL_3 := 3
const LEVEL_4 := 4
const LEVEL_5 := 5
const LEVEL_6 := 6
const FINAL_TEST := 7

const DEFAULT_TRANSITION_TIME := 1.6
const RESTART_TRANSITION_TIME := 0.7
const FAKE_ESCAPE_TIME := 2.2

const C_FURNITURE := Color("576b70")
const C_SIGN := Color("9c6d58")
const C_DOOR := Color("7c9d76")
const C_LOCKED := Color("96585c")
const C_NOTE := Color("c1ad72")
const C_TERMINAL := Color("5b86a3")
const C_CHANGED := Color("6e4f58")
const C_FINAL_CHANGED := Color("654c5d")

@onready var player: TrustPlayer = $Player

var deception: DeceptionManager
var objectives: ObjectiveManager
var audio_hooks: AudioHooks
var ui: GameUI
var world: PlaceholderWorld
var level := LEVEL_1
var room_phase := 0
var flags: Dictionary = {}
var interact_cooldown := 0.0
var transitioning := false
var ending := false
var in_title := true

func _ready() -> void:
	# Game must receive Esc while paused, but the player must not keep moving.
	process_mode = Node.PROCESS_MODE_ALWAYS
	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	deception = DeceptionManager.new()
	objectives = ObjectiveManager.new()
	audio_hooks = AudioHooks.new()
	ui = GameUI.new()
	add_child(deception)
	add_child(objectives)
	add_child(audio_hooks)
	add_child(ui)
	player.rule_manager = deception
	objectives.objective_changed.connect(ui.set_objective)
	ui.play_requested.connect(start_game)
	ui.quit_requested.connect(quit_game)
	ui.resume_requested.connect(resume_game)
	ui.restart_requested.connect(restart_from_pause)
	ui.main_menu_requested.connect(show_title_screen)
	player.movement_enabled = false
	show_title_screen()

func _process(delta: float) -> void:
	if not in_title and not ending and Input.is_action_just_pressed("pause"):
		toggle_pause()
	if get_tree().paused or in_title:
		return
	interact_cooldown = maxf(0.0, interact_cooldown - delta)
	if ending:
		if Input.is_action_just_pressed("restart"):
			show_title_screen()
		return
	if Input.is_action_just_pressed("restart") and not transitioning:
		restart_level()
		return
	if transitioning:
		ui.set_interaction_prompt("")
		return
	var target: Interactable = world.nearest_interactable(player.global_position)
	if target == null:
		ui.set_interaction_prompt("")
		return
	ui.set_interaction_prompt("E — INTERACT: " + target.display_name)
	if Input.is_action_just_pressed("interact") and interact_cooldown <= 0.0:
		interact_cooldown = 0.22
		handle_interaction(target.interaction_id, target.interaction_text)

func show_title_screen() -> void:
	get_tree().paused = false
	in_title = true
	ending = false
	transitioning = false
	player.movement_enabled = false
	if world != null:
		world.visible = false
	ui.show_title()

func start_game() -> void:
	in_title = false
	player.movement_enabled = true
	ui.show_game_hud()
	load_level(LEVEL_1)
	show_transition("LEVEL 1 — TRUST", 1.4)

func quit_game() -> void:
	get_tree().quit()

func toggle_pause() -> void:
	if get_tree().paused:
		resume_game()
	else:
		get_tree().paused = true
		ui.show_pause()

func resume_game() -> void:
	ui.hide_pause()
	get_tree().paused = false

func restart_from_pause() -> void:
	get_tree().paused = false
	ui.hide_pause()
	restart_level()

func restart_level() -> void:
	player.movement_enabled = true
	load_level(level)
	show_transition("RESTARTING LEVEL", RESTART_TRANSITION_TIME)

func load_level(next_level: int) -> void:
	level = next_level
	room_phase = 0
	flags.clear()
	ending = false
	deception.reset()
	ui.hide_dialogue()
	build_level()

func build_level() -> void:
	if world != null:
		world.queue_free()
	world = PlaceholderWorld.new()
	world.name = "PlaceholderWorld"
	add_child(world)
	move_child(world, 0)
	world.build_background()
	match level:
		LEVEL_1: setup_level_1()
		LEVEL_2: setup_level_2()
		LEVEL_3: setup_level_3()
		LEVEL_4: setup_level_4()
		LEVEL_5: setup_level_5()
		LEVEL_6: setup_level_6()
		FINAL_TEST: setup_final_test()

func begin_room(room_name: String, objective: String, spawn_position: Vector2) -> void:
	ui.set_header(level_heading() + "  /  " + room_name)
	objectives.set_objective(objective)
	player.global_position = spawn_position
	world.add_border()

func level_heading() -> String:
	match level:
		LEVEL_1: return "LEVEL 1 — TRUST"
		LEVEL_2: return "LEVEL 2 — SOMETHING'S WRONG"
		LEVEL_3: return "LEVEL 3 — FALSE DIRECTIONS"
		LEVEL_4: return "LEVEL 4 — FALSE REALITY"
		LEVEL_5: return "LEVEL 5 — NOTHING IS RELIABLE"
		LEVEL_6: return "LEVEL 6 — TRUST"
		FINAL_TEST: return "?!"
	return ""

func add_wall(position: Vector2, dimensions: Vector2, color: Color = PlaceholderWorld.WALL_COLOR) -> void:
	world.add_wall(position, dimensions, color)

func add_furniture(position: Vector2, dimensions: Vector2, color: Color = C_FURNITURE) -> void:
	world.add_furniture(position, dimensions, color)

func add_interactable(id: String, title: String, text: String, position: Vector2, color: Color, dimensions := Vector2(28, 28)) -> void:
	world.add_interactable(id, title, text, position, color, dimensions)

func add_room_label(text: String, position: Vector2) -> void:
	world.add_room_label(text, position)

func show_dialogue(text: String) -> void:
	audio_hooks.play_hook("dialogue")
	ui.show_dialogue(text)

func show_transition(text: String, seconds: float = DEFAULT_TRANSITION_TIME) -> void:
	audio_hooks.play_hook("transition")
	transitioning = true
	ui.show_transition(text, seconds)
	get_tree().create_timer(seconds).timeout.connect(func(): transitioning = false)

# Level 1 is intentionally reliable: desk -> clock code -> key -> exit.
func setup_level_1() -> void:
	begin_room("RECEPTION", "Inspect the reception desk.", Vector2(78, 285))
	add_room_label("RECEPTION", Vector2(42, 78))
	add_room_label("MAINTENANCE", Vector2(250, 78))
	add_room_label("EAST HALL", Vector2(468, 78))
	add_wall(Vector2(210, 105), Vector2(12, 126))
	add_wall(Vector2(210, 278), Vector2(12, 92))
	add_wall(Vector2(425, 105), Vector2(12, 126))
	add_wall(Vector2(425, 278), Vector2(12, 92))
	add_furniture(Vector2(105, 125), Vector2(88, 28))
	add_furniture(Vector2(315, 240), Vector2(115, 26))
	add_furniture(Vector2(530, 115), Vector2(78, 28))
	add_interactable("l1_welcome", "SIGN", "WELCOME. All plaques and signs in this building describe what they do.", Vector2(82, 210), C_SIGN)
	add_interactable("l1_desk", "DESK", "The inspection log is closed.", Vector2(115, 190), C_TERMINAL, Vector2(40, 28))
	add_interactable("l1_clock_a", "CLOCK", "The left clock reads 3.", Vector2(275, 125), C_NOTE)
	add_interactable("l1_clock_b", "CLOCK", "The middle clock reads 1.", Vector2(320, 125), C_NOTE)
	add_interactable("l1_clock_c", "CLOCK", "The right clock reads 4.", Vector2(365, 125), C_NOTE)
	add_interactable("l1_switch_3", "BUTTON 3", "A button marked 3.", Vector2(270, 180), C_TERMINAL)
	add_interactable("l1_switch_1", "BUTTON 1", "A button marked 1.", Vector2(320, 180), C_TERMINAL)
	add_interactable("l1_switch_4", "BUTTON 4", "A button marked 4.", Vector2(370, 180), C_TERMINAL)
	add_interactable("l1_locker", "LOCKER", "A locker marked BRASS KEY.", Vector2(500, 205), C_LOCKED, Vector2(36, 38))
	add_interactable("l1_exit", "EXIT", "The east exit has a brass-key lock.", Vector2(575, 180), C_LOCKED, Vector2(34, 52))

func setup_level_2() -> void:
	begin_room("CALIBRATION", "Inspect the calibration terminal.", Vector2(320, 290))
	add_wall(Vector2(320, 215), Vector2(250, 16))
	add_wall(Vector2(155, 135), Vector2(16, 120))
	add_wall(Vector2(485, 295), Vector2(16, 70))
	add_furniture(Vector2(500, 105), Vector2(90, 26))
	add_interactable("l2_terminal", "TERMINAL", "SYSTEM CALIBRATION READY.", Vector2(320, 270), C_TERMINAL, Vector2(40, 34))
	add_interactable("l2_wall_note", "NOTE", "A fixed wall is useful when testing a single step.", Vector2(115, 250), C_NOTE)
	add_interactable("l2_route", "PLAQUE", "SERVICE PANEL — WEST", Vector2(420, 175), C_SIGN, Vector2(44, 28))
	add_interactable("l2_service", "SERVICE", "A service panel with a green indicator.", Vector2(88, 92), C_TERMINAL, Vector2(36, 32))
	add_interactable("l2_exit", "EXIT", "The calibrated exit is north.", Vector2(320, 62), C_LOCKED, Vector2(52, 34))

func setup_level_3() -> void:
	if room_phase == 1:
		begin_room("LIBRARY", "Read the library index.", Vector2(320, 100))
		add_furniture(Vector2(145, 145), Vector2(115, 34))
		add_furniture(Vector2(495, 145), Vector2(115, 34))
		add_furniture(Vector2(320, 235), Vector2(90, 34))
		add_interactable("l3_index", "INDEX", "EXIT ROUTE: ARCHIVE.\nThe index is a fixed record, not a visitor sign.", Vector2(320, 180), C_NOTE, Vector2(38, 32))
		add_interactable("l3_return", "RETURN", "A plaque: CROSSROADS.", Vector2(320, 298), C_DOOR, Vector2(52, 34))
		return
	begin_room("CROSSROADS", "Determine which route contains the exit record.", Vector2(320, 280))
	add_wall(Vector2(320, 165), Vector2(155, 16))
	add_furniture(Vector2(155, 276), Vector2(72, 28))
	add_furniture(Vector2(485, 276), Vector2(72, 28))
	add_interactable("l3_blue_sign", "BLUE SIGN", "LIBRARY  →\nARCHIVE  ←", Vector2(410, 225), C_SIGN, Vector2(54, 28))
	add_interactable("l3_notice", "NOTICE", "Blue visitor signs were repainted last night.\nOnly fixed plaques name rooms.", Vector2(165, 220), C_NOTE, Vector2(38, 30))
	add_interactable("l3_library", "LIBRARY", "A fixed plaque: LIBRARY.", Vector2(62, 180), C_DOOR, Vector2(34, 52))
	add_interactable("l3_archive", "ARCHIVE", "A fixed plaque: ARCHIVE.", Vector2(576, 180), C_DOOR, Vector2(34, 52))

func setup_level_4() -> void:
	if room_phase == 0:
		begin_room("RECEPTION", "Inspect the reception inventory, then enter the archive.", Vector2(320, 280))
		add_furniture(Vector2(145, 130), Vector2(70, 28))
		add_furniture(Vector2(495, 230), Vector2(78, 28))
		add_interactable("l4_inventory", "INVENTORY", "Movable: CHAIR, CLOCK, RECORD CASE.\nFixed: BRASS LANTERN.", Vector2(115, 220), C_NOTE, Vector2(38, 32))
		add_interactable("l4_lantern", "LANTERN", "A brass lantern bolted to the west wall.", Vector2(65, 105), C_NOTE)
		add_interactable("l4_record_case", "RECORD CASE", "A heavy record case.", Vector2(495, 155), C_FURNITURE, Vector2(32, 28))
		add_interactable("l4_archive", "ARCHIVE", "A door labelled ARCHIVE.", Vector2(320, 62), C_DOOR, Vector2(52, 34))
	elif room_phase == 1:
		begin_room("ARCHIVE", "Read the archive rule, then return.", Vector2(320, 92))
		add_furniture(Vector2(160, 135), Vector2(135, 32))
		add_furniture(Vector2(480, 135), Vector2(135, 32))
		add_furniture(Vector2(320, 248), Vector2(72, 72))
		add_interactable("l4_rule", "ARCHIVE NOTE", "On each return, movable objects shift clockwise.\nThe lantern never moves. The missing object's name opens the way.", Vector2(120, 245), C_NOTE, Vector2(38, 32))
		add_interactable("l4_return", "RETURN", "A door labelled RECEPTION.", Vector2(320, 298), C_DOOR, Vector2(52, 34))
	else:
		begin_room("RECEPTION", "Find which inventoried object is missing.", Vector2(320, 280))
		add_furniture(Vector2(145, 230), Vector2(70, 28), C_CHANGED)
		add_furniture(Vector2(495, 130), Vector2(78, 28), C_CHANGED)
		add_interactable("l4_lantern", "LANTERN", "The brass lantern is still on the west wall.", Vector2(65, 105), C_NOTE)
		add_interactable("l4_inventory", "INVENTORY", "Movable: CHAIR, CLOCK, RECORD CASE.\nFixed: BRASS LANTERN.", Vector2(115, 220), C_NOTE, Vector2(38, 32))
		add_interactable("l4_clock", "CLOCK", "The clock moved from the east wall.", Vector2(485, 265), C_FURNITURE)
		add_interactable("l4_chair", "CHAIR", "The chair moved from the north wall.", Vector2(165, 120), C_FURNITURE)
		add_interactable("l4_archive_back", "ARCHIVE", "A door labelled ARCHIVE. It returns to the archive.", Vector2(575, 180), C_LOCKED, Vector2(34, 52))
		add_interactable("l4_record", "RECORD", "A door labelled RECORD.", Vector2(320, 62), C_DOOR, Vector2(52, 34))

func setup_level_5() -> void:
	deception.set_rule(DeceptionManager.OBJECTIVE_LIE, true)
	deception.set_rule(DeceptionManager.SIGN_LIE, true)
	deception.set_rule(DeceptionManager.DOOR_LIE, true)
	begin_room("TEST WING", "Use the east EXIT.", Vector2(320, 282))
	add_wall(Vector2(320, 210), Vector2(175, 16))
	add_furniture(Vector2(130, 100), Vector2(85, 28))
	add_furniture(Vector2(510, 100), Vector2(85, 28))
	add_interactable("l5_exit_sign", "EXIT SIGN", "EXIT  →", Vector2(445, 240), C_SIGN, Vector2(48, 26))
	add_interactable("l5_card", "METAL CARD", "Painted arrows and displayed objectives are visitor information.\nEngraved symbols identify active terminals.", Vector2(105, 225), C_NOTE, Vector2(38, 32))
	add_interactable("l5_triangle", "△ TERMINAL", "An engraved triangle terminal.", Vector2(115, 145), C_TERMINAL, Vector2(40, 32))
	add_interactable("l5_service", "SERVICE", "A fixed plaque: SERVICE.", Vector2(88, 78), C_TERMINAL, Vector2(36, 32))
	add_interactable("l5_false_exit", "EXIT", "A painted EXIT door. It is sealed.", Vector2(575, 180), C_LOCKED, Vector2(34, 52))
	add_interactable("l5_button_2", "PANEL 2", "A numbered power panel.", Vector2(250, 145), C_TERMINAL)
	add_interactable("l5_button_3", "PANEL 3", "A numbered power panel.", Vector2(320, 105), C_TERMINAL)
	add_interactable("l5_button_1", "PANEL 1", "A numbered power panel.", Vector2(390, 145), C_TERMINAL)
	add_interactable("l5_trust", "TRUST", "An engraved TRUST door.", Vector2(320, 62), C_LOCKED, Vector2(52, 34))

func setup_level_6() -> void:
	begin_room("TRUST", "ESCAPE", Vector2(320, 280))
	add_furniture(Vector2(135, 160), Vector2(100, 28))
	add_furniture(Vector2(505, 160), Vector2(100, 28))
	add_interactable("l6_plan", "EVACUATION PLAN", "All information in this room is current.\nCollect the three verification notes, then set the panels in their recorded order.", Vector2(320, 220), C_NOTE, Vector2(42, 32))
	add_interactable("l6_note_a", "NOTE A", "FIRST: the panel beside the brass lantern.", Vector2(110, 225), C_NOTE)
	add_interactable("l6_note_b", "NOTE B", "SECOND: the panel beneath the clock.", Vector2(530, 225), C_NOTE)
	add_interactable("l6_note_c", "NOTE C", "THIRD: the panel beside the record case.", Vector2(320, 115), C_NOTE)
	add_interactable("l6_lantern", "LANTERN", "A brass lantern beside panel 2.", Vector2(115, 125), C_FURNITURE)
	add_interactable("l6_clock", "CLOCK", "A clock above panel 1.", Vector2(320, 165), C_FURNITURE)
	add_interactable("l6_record", "RECORD CASE", "A record case beside panel 3.", Vector2(525, 125), C_FURNITURE)
	add_interactable("l6_button_2", "PANEL 2", "A verification panel.", Vector2(150, 125), C_TERMINAL)
	add_interactable("l6_button_1", "PANEL 1", "A verification panel.", Vector2(320, 195), C_TERMINAL)
	add_interactable("l6_button_3", "PANEL 3", "A verification panel.", Vector2(490, 125), C_TERMINAL)
	add_interactable("l6_exit", "TRUST", "The north exit is locked by the verification panels.", Vector2(320, 62), C_LOCKED, Vector2(52, 34))

func setup_final_test() -> void:
	deception.set_rule(DeceptionManager.MOVEMENT_LIE, true)
	deception.set_rule(DeceptionManager.OBJECTIVE_LIE, true)
	deception.set_rule(DeceptionManager.ENVIRONMENT_LIE, true)
	deception.set_rule(DeceptionManager.DOOR_LIE, true)
	deception.set_rule(DeceptionManager.SIGN_LIE, true)
	begin_room("FINAL TEST", "Use the east EXIT.", Vector2(320, 282))
	add_wall(Vector2(320, 210), Vector2(175, 16), C_FINAL_CHANGED)
	add_furniture(Vector2(145, 120), Vector2(100, 28), C_FINAL_CHANGED)
	add_furniture(Vector2(495, 250), Vector2(100, 28), C_FINAL_CHANGED)
	add_interactable("final_sign", "EXIT SIGN", "EXIT  →\nTHIS WAY", Vector2(450, 240), C_SIGN, Vector2(48, 26))
	add_interactable("final_note", "FIXED NOTE", "Paint repeats. Plaques record.\nA single step against a wall reveals a reversed response.\nThe old clock sequence is still recorded.", Vector2(108, 225), C_NOTE, Vector2(40, 34))
	add_interactable("final_terminal", "CALIBRATION", "An engraved calibration terminal.", Vector2(100, 80), C_TERMINAL, Vector2(42, 32))
	add_interactable("final_clock_a", "CLOCK", "The left clock reads 3.", Vector2(250, 130), C_NOTE)
	add_interactable("final_clock_b", "CLOCK", "The middle clock reads 1.", Vector2(320, 130), C_NOTE)
	add_interactable("final_clock_c", "CLOCK", "The right clock reads 4.", Vector2(390, 130), C_NOTE)
	add_interactable("final_button_3", "BUTTON 3", "A brass code button.", Vector2(250, 170), C_TERMINAL)
	add_interactable("final_button_1", "BUTTON 1", "A brass code button.", Vector2(320, 170), C_TERMINAL)
	add_interactable("final_button_4", "BUTTON 4", "A brass code button.", Vector2(390, 170), C_TERMINAL)
	add_interactable("final_false_exit", "EXIT", "A painted EXIT door.", Vector2(575, 180), C_LOCKED, Vector2(34, 52))
	add_interactable("final_trust", "TRUST", "An engraved TRUST door.", Vector2(320, 62), C_LOCKED, Vector2(52, 34))

func append_code(value: int, expected: Array[int], success_flag: String, success_text: String) -> void:
	var entered: Array = flags.get("code", [])
	entered.append(value)
	flags["code"] = entered
	if entered.size() > expected.size() or entered.back() != expected[entered.size() - 1]:
		flags["code"] = []
		show_dialogue("The panel gives one calm click, then resets. The recorded sequence has not changed.")
		return
	if entered.size() == expected.size():
		flags[success_flag] = true
		flags["code"] = []
		show_dialogue(success_text)
	else:
		show_dialogue("The panel accepts that step.")

func handle_interaction(id: String, fallback_text: String) -> void:
	match id:
		"l1_desk":
			flags["desk"] = true
			objectives.set_objective("Read the clocks, then enter their order on the numbered buttons.")
			show_dialogue("Inspection log: “For the locker, use the clocks left to right. The locker holds the brass key.”")
		"l1_switch_3", "l1_switch_1", "l1_switch_4":
			if not flags.get("desk", false):
				show_dialogue("The panel is idle. The reception desk may explain its use.")
			else:
				append_code(int(id.right(1)), [3, 1, 4], "l1_code", "The locker unlocks with a green light.")
				if flags.get("l1_code", false): objectives.set_objective("Take the brass key from the locker.")
		"l1_locker":
			if flags.get("l1_code", false):
				flags["key"] = true
				objectives.set_objective("Use the east exit.")
				show_dialogue("You take the brass key. The exit lock has the same brass symbol.")
			else: show_dialogue("Three numbered buttons control this locker.")
		"l1_exit":
			if flags.get("key", false): advance_level()
			else: show_dialogue("The brass-key lock needs the locker key.")
		"l2_terminal":
			flags["calibrated"] = true
			deception.set_rule(DeceptionManager.MOVEMENT_LIE, true)
			objectives.set_objective("Reach the west service panel.")
			show_dialogue("CALIBRATION COMPLETE.")
		"l2_service":
			if flags.get("calibrated", false):
				flags["service"] = true
				objectives.set_objective("Reach the north exit.")
				show_dialogue("The service panel releases the north exit. The room remains calibrated.")
			else: show_dialogue("The service indicator is dark.")
		"l2_exit":
			if flags.get("service", false): advance_level()
			else: show_dialogue("The exit needs a service release.")
		"l3_library": change_room(1, "LIBRARY")
		"l3_index":
			flags["index"] = true
			objectives.set_objective("Return to the crossroads and use the ARCHIVE plaque.")
			show_dialogue("The index is a bound record. It identifies ARCHIVE as the EXIT route.")
		"l3_return": change_room(2, "CROSSROADS")
		"l3_archive":
			if flags.get("index", false): advance_level()
			else: show_dialogue("The ARCHIVE plaque is stable, but you do not yet know its route.")
		"l4_inventory":
			flags["inventory"] = true
			objectives.set_objective("Use the RECORD door: the record case is missing." if flags.get("rule", false) else "Enter the archive and learn its return rule.")
		"l4_archive": change_room(1, "ARCHIVE")
		"l4_rule":
			flags["rule"] = true
			objectives.set_objective("Return to reception and compare the inventory.")
		"l4_return":
			deception.set_rule(DeceptionManager.ENVIRONMENT_LIE, true)
			change_room(2, "RECEPTION")
		"l4_archive_back": change_room(1, "ARCHIVE")
		"l4_record":
			if flags.get("inventory", false) and flags.get("rule", false): advance_level()
			else: show_dialogue("The RECORD plaque is present, but the archive has not given you a reason to choose it.")
		"l5_triangle":
			flags["terminal"] = true
			deception.set_rule(DeceptionManager.MOVEMENT_LIE, true)
			objectives.set_objective("Reach the west SERVICE panel.")
			show_dialogue("The triangle terminal activates calibration. The service plaque is fixed; visitor information is not.")
		"l5_service": activate_level_5_power_sequence()
		"l5_button_2", "l5_button_3", "l5_button_1":
			if flags.get("service", false):
				append_code(int(id.right(1)), [2, 3, 1], "l5_power", "Power returns to the TRUST door.")
				if flags.get("l5_power", false): objectives.set_objective("Use the engraved TRUST door.")
			else: show_dialogue("The panels have no power. A service release may be needed.")
		"l5_false_exit": show_dialogue("The painted EXIT door stays sealed.")
		"l5_trust":
			if flags.get("l5_power", false): advance_level()
			else: show_dialogue("The engraved TRUST door has no power.")
		"l6_plan":
			objectives.set_objective("Read all three verification notes and set the recorded panel order.")
		"l6_note_a":
			flags["note_a"] = true
			show_dialogue(fallback_text)
		"l6_note_b":
			flags["note_b"] = true
			show_dialogue(fallback_text)
		"l6_note_c":
			flags["note_c"] = true
			show_dialogue(fallback_text)
		"l6_button_2", "l6_button_1", "l6_button_3":
			if flags.get("note_a", false) and flags.get("note_b", false) and flags.get("note_c", false):
				append_code(int(id.right(1)), [2, 1, 3], "l6_verified", "Verification accepted. The north TRUST exit unlocks.")
				if flags.get("l6_verified", false): objectives.set_objective("ESCAPE through the north TRUST exit.")
			else: show_dialogue("Three notes define the order. All of them are in this room.")
		"l6_exit":
			if flags.get("l6_verified", false): fake_escape()
			else: show_dialogue("The exit is truthfully locked by the verification panels.")
		"final_terminal":
			flags["terminal"] = true
			objectives.set_objective("Enter the clock sequence on the brass buttons.", "Use the east EXIT.")
			show_dialogue("The calibration plaque accepts a code request. The clocks are unchanged.")
		"final_button_3", "final_button_1", "final_button_4":
			if flags.get("terminal", false): activate_final_code_button(id)
			else: show_dialogue("The brass buttons need an active calibration request.")
		"final_card_pickup":
			flags["card"] = true
			show_dialogue("The card fits the engraved TRUST door.")
		"final_false_exit":
			add_furniture(Vector2(495, 115), Vector2(70, 20), C_FINAL_CHANGED)
			show_dialogue("The painted EXIT door returns you here. A cabinet has shifted, but the plaques remain.")
		"final_trust":
			if flags.get("card", false): true_escape()
			else: show_dialogue("The engraved TRUST door needs its record card.")
		_:
			show_dialogue(fallback_text)

func change_room(next_phase: int, transition_text: String) -> void:
	room_phase = next_phase
	build_level()
	show_transition(transition_text)

func activate_level_5_power_sequence() -> void:
	if not flags.get("terminal", false):
		show_dialogue("The SERVICE panel has no active request.")
		return
	flags["service"] = true
	deception.set_rule(DeceptionManager.MOVEMENT_LIE, false)
	deception.set_rule(DeceptionManager.ENVIRONMENT_LIE, true)
	add_furniture(Vector2(320, 105), Vector2(105, 16), C_CHANGED)
	add_interactable("l5_changed_note", "NEW NOTE", "The divider appeared. Its stamped order is 2, 3, 1.\nThe numbered power panels remain where they were.", Vector2(505, 235), C_NOTE, Vector2(38, 32))
	objectives.set_objective("Restore power using the divider's stamped order.")
	show_dialogue("The calibration ends. A divider appears across the room.")

func activate_final_code_button(id: String) -> void:
	append_code(int(id.right(1)), [3, 1, 4], "final_card", "A record card prints beside the TRUST door. The west furniture shifts.")
	if not flags.get("final_card", false):
		return
	deception.set_rule(DeceptionManager.MOVEMENT_LIE, false)
	add_furniture(Vector2(145, 260), Vector2(100, 28), C_FINAL_CHANGED)
	add_interactable("final_card_pickup", "RECORD CARD", "A card stamped TRUST.", Vector2(450, 95), C_NOTE)
	objectives.set_objective("Take the record card by the TRUST door.", "Use the east EXIT.")

func advance_level() -> void:
	if level < LEVEL_6:
		load_level(level + 1)
		show_transition(level_heading())

func fake_escape() -> void:
	player.movement_enabled = false
	show_transition("YOU ESCAPED.", FAKE_ESCAPE_TIME)
	get_tree().create_timer(FAKE_ESCAPE_TIME + 0.1).timeout.connect(func():
		player.movement_enabled = true
		load_level(FINAL_TEST)
		show_transition(level_heading())
	)

func true_escape() -> void:
	ending = true
	player.movement_enabled = false
	transitioning = true
	ui.show_ending()
