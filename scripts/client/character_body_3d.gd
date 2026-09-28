extends CharacterBody3D

@export var speed := 17.0
@export var jump_height := 6.0
@export var gravity := 100.0

@onready var camera: Camera3D = $Camera3D
@onready var model: Node3D = $DefaultChar
@onready var synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer
@onready var PlrName: Label3D = $Username

@onready var left_leg = $DefaultChar/Armature/Skeleton3D/beveled_cuboid
@onready var right_leg = $DefaultChar/Armature/Skeleton3D/beveled_cuboid_1
@onready var torso = $DefaultChar/Armature/Skeleton3D/beveled_cuboid_4
@onready var left_arm = $DefaultChar/Armature/Skeleton3D/beveled_cuboid_3
@onready var right_arm = $DefaultChar/Armature/Skeleton3D/beveled_cuboid_2
@onready var head = $DefaultChar/Armature/Skeleton3D/mesh
@onready var animPlayer = $DefaultChar/AnimationPlayer
@onready var face = $DefaultChar/Armature/Skeleton3D/face/Img
@onready var tshirt = $DefaultChar/Armature/Skeleton3D/tshirt/Img

var walk_time := 0.0
var base_scale = Vector3(3.45, 3.405, 3.35)
var base_position := Vector3.ZERO
var jump_bounce_time := 0.0
var jump_bounce_duration := 0.25

var coyote_time := 0.12
var coyote_timer := 0.0

var shift_lock := false

var username = "Unnamed":
	set(value):
		username = value
		update_name()

func _enter_tree():
	if str(name).is_valid_int():
		var player_id = name.to_int()
		set_multiplayer_authority(player_id)
		
		if synchronizer:
			synchronizer.set_multiplayer_authority(player_id)

func _ready():
	await get_tree().process_frame
	update_name() 
	
	
	if is_multiplayer_authority():
		camera.current = true
		if camera.has_method("set_process"):
			camera.set_process(true)
			camera.set_process_unhandled_input(true)
	else:
		camera.current = false
		if camera.has_method("set_process"):
			camera.set_process(false)
			camera.set_process_unhandled_input(false)
			
func update_name():
	if is_inside_tree() and has_node("Username"):
		$Username.text = username

func _physics_process(delta):
	if not is_multiplayer_authority():
		return
		
	username = Global.curr_name
	update_name()
	
	tshirt.texture = load("res://textures/tshirt/" + str(Global.tshirt) + ".png")
		
	if Input.is_action_just_pressed("shiftlock") and Global.is_builder == false: #confusing ass names i made. why using builder and is builder they sound the same?? idk man... blame it on me from like a 3 days ago
		shift_lock = !shift_lock
		
	if Input.is_action_just_pressed("toggle_builder") and Global.using_builder:
		position = Vector3(0, 10, 0)
		Global.is_builder = not Global.is_builder
		Global.char_cantmove = not Global.char_cantmove
		
	
	if shift_lock == true:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
	if Global.is_typing:
		velocity.x = 0
		velocity.z = 0
		if not is_on_floor():
			velocity.y -= gravity * delta
		else:
			velocity.y = 0
		move_and_slide()
		return
		
	if Global.is_builder or Global.char_cantmove:
		position = Vector3(0, 0, 0)
		velocity.x = 0
		velocity.z = 0
		visible = false
		move_and_slide()
		return
	
	visible = true
	var input = Vector2(
		Input.get_action_strength("right") - Input.get_action_strength("left"),
		Input.get_action_strength("forward") - Input.get_action_strength("back")
	).normalized()

	var move_dir = Vector3.ZERO

	if camera and camera.current:
		var forward = -camera.global_transform.basis.z
		var right = camera.global_transform.basis.x

		forward.y = 0
		right.y = 0

		move_dir = (forward.normalized() * input.y + right.normalized() * input.x).normalized()

	velocity.x = move_dir.x * speed
	velocity.z = move_dir.z * speed
	
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer -= delta

	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0

	if Input.is_action_just_pressed("jump") and coyote_timer > 0.0:
		
		velocity.y = sqrt(2.0 * gravity * jump_height)
		
		velocity.y = sqrt(2.0 * gravity * jump_height)
		jump_bounce_time = jump_bounce_duration
		
	if Input.is_action_just_pressed("reset"):
		position = Vector3(0, 10, 0)

	move_and_slide()
	
	if not is_on_floor():
		if velocity.y < 0.0:
			animPlayer.play("fall")
		else:
			animPlayer.play("jump")
	elif move_dir.length() > 0.1:
		animPlayer.play("walk")
	else:
		animPlayer.play("idle")

	if move_dir.length() > 0.1:
		walk_time += delta * 10.0

		var bounce = abs(sin(walk_time))

		var stretch = 1.0 + bounce * 0.15
		var squash = 1.0 - bounce * 0.18
		

		model.scale = Vector3(
			base_scale.x * squash,
			base_scale.y * stretch,
			base_scale.z * squash
		)

		if shift_lock:
			var forward = -camera.global_transform.basis.z
			forward.y = 0
			forward = forward.normalized()

			var target = atan2(forward.x, forward.z)
			model.rotation.y = lerp_angle(model.rotation.y, target, 0.25)
		else:
			var target = atan2(move_dir.x, move_dir.z)
			model.rotation.y = lerp_angle(model.rotation.y, target, 0.2)

	if jump_bounce_time > 0.0:
		jump_bounce_time -= delta
	
		var t = 1.0 - (jump_bounce_time / jump_bounce_duration)
		var bounce = sin(t * PI)

		var stretch = 1.0 + bounce * 0.15
		var squash = 1.0 - bounce * 0.18

		model.scale = Vector3(
			base_scale.x * squash,
			base_scale.y * stretch,
			base_scale.z * squash
		)
	else:
		model.scale = model.scale.lerp(base_scale, 10.0 * delta)
