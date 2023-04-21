extends AudioStreamPlayer

@onready var parent = $".."
var velocity:float = 0.0
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if(not is_multiplayer_authority()): return
	velocity = parent.linear_velocity.length()
	if(velocity < 25):
		volume_db = lerp(volume_db,remap(velocity,0,15,-50,-20),delta*2)
	else:
		volume_db = -10
	pitch_scale = lerp(pitch_scale,remap(velocity,0,30,0.5,3),delta*0.5)
	
