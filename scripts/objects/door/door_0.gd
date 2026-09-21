extends Node3D

var door_open:bool = false;
var door_animating:bool = false;
var timer_started:bool = false;

func reset_states():
	door_open = false;
	door_animating = false;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_door_0_area_body_entered(body: Node3D) -> void:
	if (body.editor_description == "player"):
		if (door_open and not door_animating):
			$AnimationPlayer.play("door0_close");
			door_animating = true;
		elif (not door_open and not door_animating):
			$AnimationPlayer.play("door0_open");
			door_animating = true;
			
			
func _on_door_0_area_body_exited(body: Node3D) -> void:
	if (body.editor_description == "player" and not timer_started):
		$"Door Animation Timer".start();
		timer_started = true;
		print("Called!")
		


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	door_open = not(door_open); # Inverts the door_open state nothing else.
	door_animating = false;
		


func _on_door_animation_timer_timeout() -> void:
	if (timer_started):
		if (door_open):
			$AnimationPlayer.play("door0_close");
			door_animating = true;
		elif (not door_open):
			$AnimationPlayer.play("door0_open");
			door_animating = true;
		print("Called - timer!")	
		timer_started = false;
