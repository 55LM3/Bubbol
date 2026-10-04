extends Control

@onready var label = $Label
@onready var vbox = $PanelContainer/HBoxContainer/spawn/vbox



func _on_hideui_pressed() -> void:
	label.visible = not label.visible


func _on_spawn_pressed() -> void:
	vbox.visible = not vbox.visible
