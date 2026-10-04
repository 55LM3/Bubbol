extends Node3D

@onready var animPlayer = $DefaultChar/AnimationPlayer






func _ready() -> void:
	animPlayer.play("idle")
