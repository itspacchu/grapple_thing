extends Control

func _process(delta):
	if(not is_multiplayer_authority()):
		hide()
