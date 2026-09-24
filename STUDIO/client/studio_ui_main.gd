extends Control

@onready var label = $Label



func _on_hideui_pressed() -> void:
	label.visible = not label.visible
