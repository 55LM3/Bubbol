extends Camera3D

@export var sensitivity := 0.0025
@export var height := 2.0
@export var cameraSmoothness := 0.15

@export var min_zoom := 0.1
@export var max_zoom := 80.0
@export var base_zoom := 8.0
@export var zoom_speed := 2.0

var yaw := 0.0
var pitch := 0.0
var zoom := base_zoom
var rotating := false
var follow_pos: Vector3
var follow_velocity: Vector3

@onready var player := get_parent() as CharacterBody3D

func _ready():
	if not player.is_multiplayer_authority():
		current = false
		set_process(false)
		set_process_unhandled_input(false)
		return

	current = true
	follow_pos = player.global_position + Vector3.UP * height

func _unhandled_input(event):
	if not player.is_multiplayer_authority():
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			rotating = event.pressed

		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = clamp(zoom - zoom_speed, min_zoom, max_zoom)

		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = clamp(zoom + zoom_speed, min_zoom, max_zoom)

	elif event is InputEventMouseMotion and rotating:
		yaw -= event.relative.x * sensitivity
		pitch = clamp(
			pitch - event.relative.y * sensitivity,
			-1.4,
			1.4
		)

func _process(delta):
	if not player.is_multiplayer_authority():
		return

	var target = player.global_position + Vector3.UP * height

	var stiffness = 70.0
	var damping = 0.8

	var force = (target - follow_pos) * stiffness
	follow_velocity = (follow_velocity + force * delta) * pow(damping, delta * 60.0)

	follow_pos += follow_velocity * delta

	var rot = Basis.from_euler(Vector3(pitch, yaw, 0.0))
	var cam_pos = follow_pos + rot * Vector3(0, 0, zoom)

	var target_transform = Transform3D(rot, cam_pos)
	global_transform = global_transform.interpolate_with(target_transform, cameraSmoothness)
