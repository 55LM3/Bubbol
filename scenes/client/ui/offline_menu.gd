extends Control

@onready var customizeUI = $customize
@onready var settingsUI = $settings
@onready var tutUI = $BuilderTut

func _on_catalog_pressed() -> void:
	customizeUI.visible = not customizeUI.visible





func _on_settings_pressed() -> void:
	settingsUI.visible = not settingsUI.visible







func _on_studio_pressed() -> void:
	visible = not visible
	Global.is_builder = true
	DiscordRPC.state = "Cooking something up..."
	DiscordRPC.refresh()
	



func _on_tut_pressed() -> void:
	tutUI.visible = not tutUI.visible
