extends Node3D
@onready var parent = get_node("../../..")
var old_vel = 0
func _process(delta):
	var vel = parent.linear_velocity
	
	if(vel.y - old_vel > 2):
		print(old_vel - vel.y)
		$AnimationPlayer.play("shake")
	old_vel = vel.y
