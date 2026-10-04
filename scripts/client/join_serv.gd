extends Control
@export var player_scene: PackedScene
@export var part_scene: PackedScene




func _on_offline_pressed() -> void:
	visible = false
	#Global.is_builder = true
	var player = player_scene.instantiate()
	get_tree().current_scene.add_child(player)
