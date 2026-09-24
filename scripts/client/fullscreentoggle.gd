extends Node

var fullscreen = false


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("fullscreen"):
		if fullscreen == false:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			fullscreen = true
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MAXIMIZED)
			fullscreen = false
