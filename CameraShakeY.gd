extends Node3D
@onready var parent:RigidBody3D = get_node("../../..")
var old_vel = 0
func _process(delta):
	var vel = parent.linear_velocity
	
	if(vel.y - old_vel > 2):
		$AnimationPlayer.play("shake")
	elif(len(parent.get_colliding_bodies()) < 1):
		$AnimationPlayer.play("new_animation",-1,0.3)
	old_vel = vel.y
	
	
