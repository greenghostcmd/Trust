extends Node
class_name AudioHooks

## Gameplay emits named cues here so future audio can be attached without
## coupling puzzle code to AudioStreamPlayer nodes.
signal cue_requested(cue_name: String)

func play_hook(cue_name: String) -> void:
	cue_requested.emit(cue_name)
