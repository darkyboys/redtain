extends Node

var paused := false
## an event that is called when paused state is set- passes a bool with the new state
signal paused_changed

# Called when the node enters the scene tree for the first time.
func _ready():
	#set paused on startup
	set_paused(false)



func set_paused(_paused : bool) -> void:
	paused = _paused
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if _paused else Input.MOUSE_MODE_CAPTURED
	paused_changed.emit(paused)


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_action_pressed("ui_cancel"):
			paused = !paused
			set_paused(paused)
