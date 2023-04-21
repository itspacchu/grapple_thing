extends Label

var timer := Timer.new()


# Called when the node enters the scene tree for the first time.
func _ready():
	add_child(timer)
	timer.wait_time = 5.0
	timer.one_shot = true
	timer.connect("timeout", _on_timer_timeout)
	timer.start()

func writeText(str:String):
	text = str.substr(0,100)

func _on_timer_timeout() -> void:
	queue_free()
