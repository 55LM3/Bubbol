extends Camera3D
# why the fuck do i keep turning into lua?
#fuck this shit fuck this shit im not coding the gizmos man i think a really barebones editor for now IS FINE. its better than nothing :shrug:
#yes im crazy i know im crazy i put the entire f ucking level editor in the camera script
#ykw im adding the gizmos
#maybe later actually lmao

#NOTE TO SELF!! DO THIS COMMAND AFTER YOU UPDATE GAME IN TERMINAL: git push origin main --force

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

var selected_object: Node3D = null
var dragging_object := false
var drag_distance := 0.0

const default_tex = preload("res://textures/world/object/BubbolDefaultTexture.png")

@onready var player := get_parent() as CharacterBody3D

@onready var savedialog = $Save
@onready var loaddialog = $Load

@onready var studioUi = $StudioUiMain

@onready var PosUI = $StudioUiMain/PartOptions/container/POS
@onready var RotUI = $StudioUiMain/PartOptions/container/ROT
@onready var SizeUI = $StudioUiMain/PartOptions/container/SCALE
@onready var TxtObjUI = $StudioUiMain/PartOptions/container/TXT
@onready var canseeUI = $StudioUiMain/PartOptions/container/CanSee
@onready var cancollideUI = $StudioUiMain/PartOptions/container/CanCollide
@onready var baseobj = $StudioUiMain/tree/container/object
@onready var treeContainer = $StudioUiMain/tree/container
@onready var spawnPartUI = $StudioUiMain/PanelContainer/HBoxContainer/part
@onready var spawnSphereUI = $StudioUiMain/PanelContainer/HBoxContainer/sphere
@onready var spawnNPCUI = $StudioUiMain/PanelContainer/HBoxContainer/NPC

@export var part_scene: PackedScene
@export var sphere_scene: PackedScene
@export var billboard_scene: PackedScene
@export var npc_scene: PackedScene
@export var text3d_scene: PackedScene


var can_use_builder = true

var part_count = 0


func spawn_part(pos: Vector3, size: Vector3, color: Color, rot: Vector3, isvisible: bool, cancollide: bool):
	var part = part_scene.instantiate()

	part.position = pos
	part.scale = size
	part.rotation = rot
	part.visible = isvisible
	
	var box: CSGShape3D = part.get_node("PartMain")
	box.use_collision = cancollide

	var mat = StandardMaterial3D.new()

	mat.albedo_texture = default_tex
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST

	mat.albedo_color = color

	box.material_override = mat

	get_tree().current_scene.add_child(part)
	part.add_to_group("prt")
	
	part_count += 1
	part.name = "Part" + str(part_count)
	
	var newprt = baseobj.duplicate()
	newprt.text = part.name
	
	treeContainer.add_child(newprt)
	
	
func spawn_sphere(pos: Vector3, size: Vector3, color: Color, rot: Vector3, isvisible: bool, cancollide: bool):
	var part = sphere_scene.instantiate()

	part.position = pos
	part.scale = size
	part.rotation = rot
	part.visible = isvisible
	
	var box: CSGShape3D = part.get_node("PartMain")
	box.use_collision = cancollide

	var mat = StandardMaterial3D.new()

	mat.albedo_texture = default_tex
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST

	mat.albedo_color = color

	box.material_override = mat

	get_tree().current_scene.add_child(part)
	part.add_to_group("prt")
	
	part_count += 1
	part.name = "Sphere" + str(part_count)
	
	var newprt = baseobj.duplicate()
	newprt.text = part.name
	
	treeContainer.add_child(newprt)
	
	
	
	
func spawn_billboard(pos: Vector3, size: Vector3, obj_text: String, rot: Vector3 = Vector3.ZERO, isvisible: bool = true):
	var part = billboard_scene.instantiate()
	
	part.position = pos
	part.scale = size
	part.rotation = rot
	part.visible = isvisible
	
	var objmsg: Label3D = part.get_node("msg")
	objmsg.text = obj_text
	
	get_tree().current_scene.add_child(part)
	part.add_to_group("prt")
	
	part_count += 1
	part.name = "Billboard" + str(part_count)
	
	var newprt = baseobj.duplicate()
	newprt.text = part.name
	
	treeContainer.add_child(newprt)
	
	
	
	
	
func spawn_text3d(pos: Vector3, size: Vector3, obj_text: String, rot: Vector3 = Vector3.ZERO, isvisible: bool = true):
	var part = text3d_scene.instantiate()
	
	part.position = pos
	part.scale = size
	part.rotation = rot
	part.visible = isvisible
	
	var objmsg: Label3D = part.get_node("msg")
	objmsg.text = obj_text
	
	get_tree().current_scene.add_child(part)
	part.add_to_group("prt")
	
	part_count += 1
	part.name = "Text" + str(part_count)
	
	var newprt = baseobj.duplicate()
	newprt.text = part.name
	
	treeContainer.add_child(newprt)
	
	
	
	
func spawn_npc(pos: Vector3, size: Vector3, rot: Vector3, isvisible: bool, cancollide: bool):
	var npc = npc_scene.instantiate()
	
	npc.position = pos
	npc.scale = size
	npc.rotation = rot
	
	var box: CSGShape3D = npc.get_node("PartMain")
	box.use_collision = cancollide
	
	get_tree().current_scene.add_child(npc)
	npc.add_to_group("prt")


func save_level(path: String, level_name: String, creator: String, description: String):
	var level_data = {
		"name": level_name,
		"creator": creator,
		"description": description,
		"version": 3,
		"parts": []
	}

	for object in get_tree().get_nodes_in_group("prt"):
		
		var type = "part"
		
		if object.scene_file_path == sphere_scene.resource_path:
			type = "sphere"
		elif object.scene_file_path == billboard_scene.resource_path:
			type = "billboard"
		elif object.scene_file_path == text3d_scene.resource_path:
			type = "text3d"
		elif object.scene_file_path == npc_scene.resource_path:
			type = "npc"
		
		var object_data = {
			"type": type,

			"position": [
				object.position.x,
				object.position.y,
				object.position.z
			],

			"scale": [
				object.scale.x,
				object.scale.y,
				object.scale.z
			],


			"rotation": [
				object.rotation.x,
				object.rotation.y,
				object.rotation.z
			],

			"visible": object.visible
		}
		
		if type == "billboard":
			var objmsg: Label3D = object.get_node("msg")
			object_data["text"] = objmsg.text
		elif type == "text3d":
			var objmsg: Label3D = object.get_node("msg")
			object_data["text"] = objmsg.text
		elif type == "npc":
			print("i dont know uhhh yeah ok")
			var box: CSGShape3D = object.get_node("PartMain")
			object_data["can_collide"] = box.use_collision
			object_data["visible"] = object.visible
		else:
			var box: CSGShape3D = object.get_node("PartMain")

			var color = Color.WHITE

			if box.material_override is StandardMaterial3D:
				color = box.material_override.albedo_color

			object_data["color"] = [
				color.r,
				color.g,
				color.b,
				color.a
			]
			
			object_data["can_collide"] = box.use_collision
		
		level_data["parts"].append(object_data)

	var file = FileAccess.open(path, FileAccess.WRITE)

	if file:
		file.store_string(JSON.stringify(level_data, "\t"))
		file.close()

		print("Saved level: ", level_name)
		
		
func load_level(path: String):
	var file = FileAccess.open(path, FileAccess.READ)

	if file == null:
		print("Failed to open level: ", path)
		return

	var text = file.get_as_text()
	file.close()

	var level_data = JSON.parse_string(text)

	if level_data == null:
		print("Invalid level!!")
		return

	for object in get_tree().get_nodes_in_group("prt"):
		object.queue_free()

	for part_data in level_data["parts"]:
		var pos = Vector3(
			part_data["position"][0],
			part_data["position"][1],
			part_data["position"][2]
		)

		var scale = Vector3(
			part_data["scale"][0],
			part_data["scale"][1],
			part_data["scale"][2]
		)

		var rotation = Vector3(
			part_data["rotation"][0],
			part_data["rotation"][1],
			part_data["rotation"][2]
		)

		var visibility = part_data.get("visible", true)

		if part_data["type"] == "billboard":
			var billboard_text = part_data.get("text", "Message")

			spawn_billboard(
				pos,
				scale,
				billboard_text,
				rotation,
				visibility
			)
		elif part_data["type"] == "text3d":
			var text3d_text = part_data.get("text", "Message")

			spawn_text3d(
				pos,
				scale,
				text3d_text,
				rotation,
				visibility
			)
		elif part_data["type"] == "npc":
			var cancollide = part_data.get("can_collide", true)
			var isvisible = part_data.get("visible", true)
			
			spawn_npc(
				pos,
				scale,
				rotation,
				isvisible,
				cancollide
				)

		else:
			var color = Color(
				part_data["color"][0],
				part_data["color"][1],
				part_data["color"][2],
				part_data["color"][3]
			)

			var cancollide = part_data.get("can_collide", true)

			if part_data["type"] == "sphere":
				spawn_sphere(
					pos,
					scale,
					color,
					rotation,
					visibility,
					cancollide
				)
			else:
				spawn_part(
					pos,
					scale,
					color,
					rotation,
					visibility,
					cancollide
				)

	print("Loaded level: ", level_data.get("name", "Unknown"))



func loadLoadDialog():
	var folder = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	var correctdir: String = folder.path_join("Bubbol Builder")
	loaddialog.current_dir = correctdir
	loaddialog.popup_centered()
	
	
func loadSaveDialog():
	var folder = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	var correctdir: String = folder.path_join("Bubbol Builder")
	savedialog.current_dir = correctdir
	savedialog.popup_centered()
	
	





func _ready():
	
	PosUI.text_submitted.connect(_on_PosUI_text_submitted)
	RotUI.text_submitted.connect(_on_RotUI_text_submitted)
	SizeUI.text_submitted.connect(_on_SizeUI_text_submitted)
	TxtObjUI.text_submitted.connect(_on_TxtObjUI_text_submitted)
	canseeUI.toggled.connect(_on_canseeUI_toggled)
	cancollideUI.toggled.connect(_on_cancollideUI_toggled)
	spawnPartUI.pressed.connect(_on_spawnPartUI_pressed)
	spawnSphereUI.pressed.connect(_on_spawnSphereUI_pressed)
	spawnNPCUI.pressed.connect(_on_spawnNPCUI_pressed)
	
	BubbolscriptRuntime.run_script("var 1")
	BubbolscriptRuntime.run_script("print var")
	
	if not player.is_multiplayer_authority():
		current = false
		set_process(false)
		set_process_unhandled_input(false)
		return

	current = true
	follow_pos = player.global_position + Vector3.UP * height

	



func select_object(mouse_pos: Vector2):
	var ray_origin = project_ray_origin(mouse_pos)
	var ray_direction = project_ray_normal(mouse_pos)

	var query = PhysicsRayQueryParameters3D.create(
		ray_origin,
		ray_origin + ray_direction * 1000.0
	)
	
	query.collision_mask = 2
	query.collide_with_areas = true

	var result = get_world_3d().direct_space_state.intersect_ray(query)

	if result.is_empty():
		selected_object = null
		dragging_object = false
		return

	var object = result.collider

	while object != null:
		if object.is_in_group("prt"):
			selected_object = object
			dragging_object = true

			drag_distance = global_position.distance_to(
				selected_object.global_position
			)

			print("selected: ", selected_object.name)
			return

		object = object.get_parent()

	selected_object = null
	dragging_object = false
		



func _unhandled_input(event):
	if not player.is_multiplayer_authority():
		return
		
	if get_viewport().gui_get_focus_owner() is LineEdit:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				select_object(event.position)
			else:
				dragging_object = false

		elif event.button_index == MOUSE_BUTTON_RIGHT:
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

	if Global.is_builder and can_use_builder:
		
		DiscordRPC.details = "In Bubbol! Builder"
		DiscordRPC.refresh()
		
		studioUi.visible = true
		
		if get_viewport().gui_get_focus_owner() is LineEdit:
			return
		
		
		if dragging_object and selected_object:
			var mouse_pos = get_viewport().get_mouse_position()

			var ray_origin = project_ray_origin(mouse_pos)
			var ray_direction = project_ray_normal(mouse_pos)

			selected_object.global_position = (
				ray_origin + ray_direction * drag_distance
			)
			
			
		if selected_object != null:
			PosUI.text = str(selected_object.position).replace("(", "").replace(")", "")
			RotUI.text = str(selected_object.rotation).replace("(", "").replace(")", "")
			SizeUI.text = str(selected_object.scale).replace("(", "").replace(")", "")

		
		var input = Vector3.ZERO

		if Input.is_key_pressed(KEY_W):
			input.z += 1

		if Input.is_key_pressed(KEY_S):
			input.z -= 1

		if Input.is_key_pressed(KEY_A):
			input.x -= 1

		if Input.is_key_pressed(KEY_D):
			input.x += 1

		if Input.is_key_pressed(KEY_E):
			input.y += 1

		if Input.is_key_pressed(KEY_Q):
			input.y -= 1
		if Input.is_action_just_pressed("scale_part"):
			if selected_object != null:
				selected_object.scale += Vector3(1, 1, 1)
				BubbolscriptRuntime.run_script("add 1")
				BubbolscriptRuntime.run_script("print var")
			else:
				Global.part_size += 1
		if Input.is_action_just_pressed("descale_part"):
			if selected_object != null:
				selected_object.scale -= Vector3(1, 1, 1)
				BubbolscriptRuntime.run_script("sub 1")
				BubbolscriptRuntime.run_script("print var")
			else:
				Global.part_size -= 1
		if Input.is_action_just_pressed("kill_part"): #NO, THIS DOES NOT ADD LIKE A KILLBRICK THING, IT JUST MURDERS THE PART!!
			if selected_object != null:
				selected_object.queue_free()
				BubbolscriptRuntime.run_script("print removing part")
		if Input.is_action_just_pressed("rotate_part"):
			if selected_object != null:
				selected_object.rotate_x(10)
				
		if Input.is_action_just_pressed("scale_up"):
			if selected_object != null:
				selected_object.scale += Vector3(0, 1, 0)
		if Input.is_action_just_pressed("scale_down"):
			if selected_object != null:
				selected_object.scale += Vector3(0, -1, 0)
				
		if Input.is_action_just_pressed("scale_x"):
			if selected_object != null:
				selected_object.scale += Vector3(1, 0, 0)
		if Input.is_action_just_pressed("unscale_x"):
			if selected_object != null:
				selected_object.scale += Vector3(-1, 0, 0)
				
		if Input.is_action_just_pressed("scale_z"):
			if selected_object != null:
				selected_object.scale += Vector3(0, 0, 1)
		if Input.is_action_just_pressed("unscale_z"):
			if selected_object != null:
				selected_object.scale += Vector3(0, 0, -1)
		if Input.is_action_just_pressed("duplicate"):
			if selected_object != null:
				var clone = selected_object.duplicate()
				get_tree().current_scene.add_child(clone)
		if Input.is_key_pressed(KEY_F):
			if selected_object != null:
				position = selected_object.position
				selected_object = null
				
		if Input.is_action_just_pressed("save"):
			loadSaveDialog()
			can_use_builder = false
			BubbolscriptRuntime.run_script("print saving level")
		if Input.is_action_just_pressed("load_level"):
			loadLoadDialog()
			BubbolscriptRuntime.run_script("print loading level")
			can_use_builder = false
				
				
		if Input.is_key_pressed(KEY_1):
			if selected_object != null:
				var box: CSGShape3D = selected_object.get_node("PartMain")

				var mat = StandardMaterial3D.new()

				mat.albedo_texture = default_tex
				mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST

				mat.albedo_color = Color.WHITE

				box.material_override = mat
		if Input.is_key_pressed(KEY_2):
			if selected_object != null:
				var box: CSGShape3D = selected_object.get_node("PartMain")

				var mat = StandardMaterial3D.new()

				mat.albedo_texture = default_tex
				mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST

				mat.albedo_color = Color.BLACK

				box.material_override = mat
		if Input.is_key_pressed(KEY_3):
			if selected_object != null:
				var box: CSGShape3D = selected_object.get_node("PartMain")

				var mat = StandardMaterial3D.new()

				mat.albedo_texture = default_tex
				mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST

				mat.albedo_color = Color(0.584, 1.0, 0.416, 1.0)

				box.material_override = mat
		if Input.is_key_pressed(KEY_4):
			if selected_object != null:
				var box: CSGShape3D = selected_object.get_node("PartMain")

				var mat = StandardMaterial3D.new()

				mat.albedo_texture = default_tex
				mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST

				mat.albedo_color = Color(0.0, 0.0, 1.0, 1.0)

				box.material_override = mat
		if Input.is_key_pressed(KEY_5):
			if selected_object != null:
				var box: CSGShape3D = selected_object.get_node("PartMain")

				var mat = StandardMaterial3D.new()

				mat.albedo_texture = default_tex
				mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST

				mat.albedo_color = Color(1.0, 0.678, 0.384, 1.0)

				box.material_override = mat
		if Input.is_key_pressed(KEY_6):
			if selected_object != null:
				var box: CSGShape3D = selected_object.get_node("PartMain")

				var mat = StandardMaterial3D.new()

				mat.albedo_texture = default_tex
				mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST

				mat.albedo_color = Color(1.0, 0.0, 0.384, 1.0)

				box.material_override = mat
				
		if Input.is_key_pressed(KEY_7):
			if selected_object != null:
				var box: CSGShape3D = selected_object.get_node("PartMain")

				var mat = StandardMaterial3D.new()

				mat.albedo_texture = default_tex
				mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST

				mat.albedo_color = Color(1.0, 0.933, 0.0, 1.0)

				box.material_override = mat
				
		if Input.is_key_pressed(KEY_8):
			if selected_object != null:
				var box: CSGShape3D = selected_object.get_node("PartMain")

				var mat = StandardMaterial3D.new()

				mat.albedo_texture = default_tex
				mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST

				mat.albedo_color = Color(0.446, 0.466, 0.521, 1.0)

				box.material_override = mat
				

		if Input.is_action_just_pressed("part"):
			spawn_part(position + Vector3(0, -2, 0), Vector3(Global.part_size, Global.part_size, Global.part_size), Color(1.0, 1.0, 1.0, 1.0), Vector3(0, 0, 0), true, true)
			
		if Input.is_action_just_pressed("sphere"):
			spawn_sphere(position + Vector3(0, -2, 0), Vector3(Global.part_size, Global.part_size, Global.part_size), Color(1.0, 1.0, 1.0, 1.0), Vector3(0, 0, 0), true, true)
		if Input.is_action_just_pressed("billboard3d"):
			spawn_billboard(position + Vector3(0, -2, 0), Vector3(Global.part_size, Global.part_size, Global.part_size), "Message")
		if Input.is_action_just_pressed("text3d"):
			spawn_text3d(position + Vector3(0, -2, 0), Vector3(Global.part_size, Global.part_size, Global.part_size), "Message")
		if Input.is_action_just_pressed("npc"):
			spawn_npc(position + Vector3(0, -2, 0), Vector3(Global.part_size, Global.part_size, Global.part_size), Vector3(0, 0, 0), true, true)

		if input.length_squared() > 0:
			input = input.normalized()

		var speed = 40 if Input.is_key_pressed(KEY_CTRL) else 20

		var forward = -global_transform.basis.z
		var right = global_transform.basis.x

		forward.y = 0
		right.y = 0

		forward = forward.normalized()
		right = right.normalized()

		var movement = right * input.x + forward * input.z
		movement.y = input.y

		if movement.length_squared() > 0:
			movement = movement.normalized()

		global_position += movement * speed * delta
		rotation = Vector3(pitch, yaw, 0)

		return

	
	studioUi.visible = false
	
	var target = player.global_position + Vector3.UP * height

	var stiffness = 70.0
	var damping = 0.8

	var force = (target - follow_pos) * stiffness

	follow_velocity = (
		follow_velocity + force * delta
	) * pow(damping, delta * 60.0)

	follow_pos += follow_velocity * delta

	var rot = Basis.from_euler(Vector3(pitch, yaw, 0.0))
	var cam_pos = follow_pos + rot * Vector3(0, 0, zoom)

	var target_transform = Transform3D(rot, cam_pos)

	global_transform = global_transform.interpolate_with(
		target_transform,
		cameraSmoothness
	)




func _on_save_file_selected(path: String) -> void:
	print("testing. path: " + path)
	var lvl_title: String = path.get_file()
	save_level(path, "A Bubbol! Level", Global.curr_name, "My amazing level!")
	can_use_builder = true
	DiscordRPC.state = "Building " + lvl_title
	DiscordRPC.refresh()
	
	




func _on_load_file_selected(path: String) -> void:
	print("gonna load. path: " + path)
	load_level(path)
	can_use_builder = true
	var lvl_title: String = path.get_file()
	DiscordRPC.state = "Building " + lvl_title
	DiscordRPC.refresh()
	
	


func _on_save_canceled() -> void:
	can_use_builder = true
	
	
	
	
	
	
func _on_load_canceled() -> void:
	can_use_builder = true
	
	
	
func _on_PosUI_text_submitted(new_pos: String) -> void: #genuinely how the fuck does just putting the new text argument fix it idfk -said by me, sepetember 20th, 2026
		print("new position: " + new_pos)
		PosUI.release_focus()
		if selected_object != null:
			var parts = new_pos.split(",")
			
			if parts.size() == 3:
				var x = parts[0].strip_edges().to_float()
				var y = parts[1].strip_edges().to_float()
				var z = parts[2].strip_edges().to_float()
			
				selected_object.position = Vector3(x, y, z)
				
				
				
				
				
	
	
func _on_RotUI_text_submitted(new_pos: String) -> void:
		print("new rotation: " + new_pos)
		RotUI.release_focus()
		if selected_object != null:
			var parts = new_pos.split(",")
			
			if parts.size() == 3:
				var x = parts[0].strip_edges().to_float()
				var y = parts[1].strip_edges().to_float()
				var z = parts[2].strip_edges().to_float()
			
				selected_object.rotation = Vector3(x, y, z)
				
				
func _on_SizeUI_text_submitted(new_pos: String) -> void:
	print("new size: " + new_pos)
	SizeUI.release_focus()
	if selected_object != null:
		var parts = new_pos.split(",")
			
		if parts.size() == 3:
			var x = parts[0].strip_edges().to_float()
			var y = parts[1].strip_edges().to_float()
			var z = parts[2].strip_edges().to_float()
			
			selected_object.scale = Vector3(x, y, z)
			
			
			
			
func _on_canseeUI_toggled(isOn) -> void:
	print("toggled visible: " + str(isOn))
	
	if selected_object != null:
		selected_object.visible = isOn
		
		
		
func _on_cancollideUI_toggled(isOn) -> void:
	print("toggled cancollide: " + str(isOn))
	
	if selected_object != null:
		var box: CSGShape3D = selected_object.get_node("PartMain")
		box.use_collision = isOn
		
		
func _on_TxtObjUI_text_submitted(new_txt) -> void:
	print("new TxtObj text: " + new_txt)
	
	if selected_object != null:
		var msg = selected_object.get_node("msg")
		
		if not msg:
			return
			
		msg.text = new_txt
		TxtObjUI.release_focus()





func _on_spawnPartUI_pressed() -> void:
	spawn_part(position + Vector3(0, -2, 0), Vector3(Global.part_size, Global.part_size, Global.part_size), Color(1.0, 1.0, 1.0, 1.0), Vector3(0, 0, 0), true, true)
	
	

func _on_spawnSphereUI_pressed() -> void:
	spawn_sphere(position + Vector3(0, -2, 0), Vector3(Global.part_size, Global.part_size, Global.part_size), Color(1.0, 1.0, 1.0, 1.0), Vector3(0, 0, 0), true, true)



func _on_spawnNPCUI_pressed() -> void:
	spawn_npc(position + Vector3(0, -2, 0), Vector3(Global.part_size, Global.part_size, Global.part_size), Vector3(0, 0, 0), true, true)
