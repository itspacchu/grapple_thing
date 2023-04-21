extends CollisionShape3D


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	disabled = not get_parent().visible
