extends Control




func _on_exit_pressed() -> void:
	visible = not visible




func _on_custom_usr_text_changed(new_text: String) -> void:
	Global.curr_name = new_text
