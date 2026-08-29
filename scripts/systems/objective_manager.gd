extends Node
class_name ObjectiveManager

signal objective_changed(text: String)

var current_objective: String = ""
var truthful_objective: String = ""

func set_objective(text: String, displayed_text := "") -> void:
	truthful_objective = text
	current_objective = displayed_text if not displayed_text.is_empty() else text
	objective_changed.emit(current_objective)
