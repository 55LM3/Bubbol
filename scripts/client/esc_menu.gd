extends Control

func _process(delta: float):
	if Input.is_action_just_pressed("esc"):
		visible = not visible
		

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_resume_pressed() -> void:
	visible = false


func _on_fps_cap_value_changed(value: float) -> void:
	Engine.max_fps = value
