extends RichTextLabel

@onready var parent = $"../.."

func _process(delta):
	if(not is_multiplayer_authority()): return
	text = "%.2f m/s" % parent.linear_velocity.length()
