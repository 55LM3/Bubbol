extends Camera3D
# why the fuck do i keep turning into lua?
#fuck this shit fuck this shit im not coding the gizmos man i think a really barebones editor for now IS FINE. its better than nothing :shrug:
#yes im crazy i know im crazy i put the entire f ucking level editor in the camera script
#ykw im adding the gizmos
#maybe later actually lmao
#ok its ACTUALLY TIME to add these gizmos.... later...

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

var using_texture = true
var was_builder := false

const default_tex = preload("res://textures/world/object/BubbolDefaultTexture.png")

@onready var player := get_parent() as CharacterBody3D

@onready var par = player.get_parent()
@onready var wrld = par.get_node_or_null("world")
@onready var spawner = wrld.get_node_or_null("Players")

@onready var savedialog = $Save
@onready var loaddialog = $Load

@onready var studioUi = $StudioUiMain

@onready var PosUI = $StudioUiMain/PartOptions/container/POS
@onready var RotUI = $StudioUiMain/PartOptions/container/ROT
@onready var SizeUI = $StudioUiMain/PartOptions/container/SCALE
@onready var TxtObjUI = $StudioUiMain/PartOptions/container/TXT
@onready var canseeUI = $StudioUiMain/PartOptions/container/CanSee
@onready var cancollideUI = $StudioUiMain/PartOptions/container/CanCollide
@onready var baseobj = $StudioUiMain/tree/scroll/container/object
@onready var treeContainer = $StudioUiMain/tree/scroll/container
@onready var spawnPartUI = $StudioUiMain/PanelContainer/HBoxContainer/spawn/vbox/part
@onready var spawnSphereUI = $StudioUiMain/PanelContainer/HBoxContainer/spawn/vbox/sphere
@onready var spawnNPCUI = $StudioUiMain/PanelContainer/HBoxContainer/spawn/vbox/NPC
@onready var spawnBillboardUI = $StudioUiMain/PanelContainer/HBoxContainer/spawn/vbox/billboard
@onready var spawnCylinderUI = $StudioUiMain/PanelContainer/HBoxContainer/spawn/vbox/cylinder
@onready var spawnTextUI = $StudioUiMain/PanelContainer/HBoxContainer/spawn/vbox/text3d
@onready var spawnScriptUI = $StudioUiMain/PanelContainer/HBoxContainer/Script
@onready var enterScriptUI = $StudioUiMain/PanelContainer/HBoxContainer/EnterScrpt
@onready var codeUI = $StudioUiMain/Editor
@onready var codeSaveUI = $StudioUiMain/Editor/Save
@onready var deleteScriptUI = $StudioUiMain/Editor/Del
@onready var loadLevelUI = $BuilderStarterUI/vbox/load
@onready var newLevelUI = $BuilderStarterUI/vbox/new
@onready var starterLevelUI = $BuilderStarterUI/vbox/starter
@onready var MOVE = $StudioUiMain/PanelContainer/HBoxContainer/Move
@onready var ROT = $StudioUiMain/PanelContainer/HBoxContainer/Rotate
@onready var SCALE = $StudioUiMain/PanelContainer/HBoxContainer/Size

@export var part_scene: PackedScene
@export var sphere_scene: PackedScene
@export var billboard_scene: PackedScene
@export var npc_scene: PackedScene
@export var text3d_scene: PackedScene
@export var cylinder_scene: PackedScene

var uv1_scale = 0.5
var grid_size := 0.5

var can_use_builder = true

var part_count = 0

var is_coding = false




var scripts := {}
var curr_script_name := ""

var undo_stack: Array[Dictionary] = []
var max_undo := 100
var loading := false
var drag_before := {}




var currScript = "" #removing later

@onready var world = get_parent().get_parent()


var selection_box: MeshInstance3D

var selection_root: Node3D
var selection_edges: Array[MeshInstance3D] = []
var selection_thickness := 0.05

var boxEdges := [
	[0,1],[2,3],[4,5],[6,7],
	[0,2],[1,3],[4,6],[5,7],
	[0,4],[1,5],[2,6],[3,7]
]




var inMenuUi = true #im trying to become better at naming variables consistently

enum GizmoMode { MOVE, ROTATE, SCALE }
var gizmo_mode := GizmoMode.MOVE
var gizmo_root: Node3D
var gizmo_holders: Array[Node3D] = []
var gizmo_size := 0.15
var gizmo_axis := -1
var gizmo_dragging := false

var g_origin := Vector3.ZERO
var g_axis_dir := Vector3.ZERO
var g_ref := Vector3.ZERO
var g_start_param := 0.0
var g_start_basis := Basis.IDENTITY
var g_start_scale := Vector3.ONE

const AXES := [Vector3.RIGHT, Vector3.UP, Vector3.BACK]
const AXIS_COLORS := [Color(1.0, 0.0, 0.0, 1.0), Color(0.0, 1.0, 0.0, 1.0), Color(0.0, 0.0, 1.0, 1.0)]


func _gizmo_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = c
	m.no_depth_test = true
	m.render_priority = 100
	return m


func _add_mesh(parent: Node3D, mesh: Mesh, pos: Vector3, c: Color) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _gizmo_mat(c)
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)


func _make_gizmo() -> void:
	gizmo_root = Node3D.new()
	gizmo_root.top_level = true
	gizmo_root.visible = false
	add_child(gizmo_root)

	for m in 3:
		var holder := Node3D.new()
		gizmo_root.add_child(holder)
		gizmo_holders.append(holder)

		for i in 3:
			var pivot := Node3D.new()
			if i == 0: pivot.rotation_degrees.z = -90
			elif i == 2: pivot.rotation_degrees.x = 90
			holder.add_child(pivot)
			var c: Color = AXIS_COLORS[i]

			if m == GizmoMode.ROTATE:
				var ring := TorusMesh.new()
				ring.inner_radius = 0.98
				ring.outer_radius = 1.02
				_add_mesh(pivot, ring, Vector3.ZERO, c)
			else:
				var shaft := CylinderMesh.new()
				shaft.top_radius = 0.025
				shaft.bottom_radius = 0.025
				shaft.height = 0.9
				_add_mesh(pivot, shaft, Vector3(0, 0.45, 0), c)

				if m == GizmoMode.MOVE:
					var cone := CylinderMesh.new()
					cone.top_radius = 0.0
					cone.bottom_radius = 0.09
					cone.height = 0.25
					_add_mesh(pivot, cone, Vector3(0, 1.0, 0), c)
				else:
					var cube := BoxMesh.new()
					cube.size = Vector3.ONE * 0.15
					_add_mesh(pivot, cube, Vector3(0, 1.0, 0), c)


func _gizmo_axis_dir(i: int) -> Vector3:
	if gizmo_mode == GizmoMode.SCALE:
		return (selected_object.global_basis.orthonormalized() * AXES[i]).normalized()
	return AXES[i]


func _update_gizmo() -> void:
	if gizmo_root == null:
		return
	if not Global.is_builder or not is_instance_valid(selected_object):
		gizmo_root.visible = false
		gizmo_dragging = false
		return

	gizmo_root.visible = true
	var pos := selected_object.global_position
	var s := global_position.distance_to(pos) * gizmo_size
	var b := Basis.IDENTITY
	if gizmo_mode == GizmoMode.SCALE:
		b = selected_object.global_basis.orthonormalized()
	gizmo_root.global_transform = Transform3D(b.scaled(Vector3.ONE * s), pos)

	for m in 3:
		gizmo_holders[m].visible = (m == gizmo_mode)


func _ray_axis(ro: Vector3, rd: Vector3, o: Vector3, axis: Vector3) -> Variant:
	var w0 := ro - o
	var b := rd.dot(axis)
	var d := rd.dot(w0)
	var e := axis.dot(w0)
	var denom := 1.0 - b * b
	if denom < 0.0001:
		return null
	return Vector2((e - b * d) / denom, (b * e - d) / denom)


func gizmo_try_begin(mouse: Vector2) -> bool:
	if gizmo_root == null or not gizmo_root.visible or not is_instance_valid(selected_object):
		return false

	var ro := project_ray_origin(mouse)
	var rd := project_ray_normal(mouse)
	var o := selected_object.global_position
	var s := gizmo_root.global_transform.basis.get_scale().x

	var best := -1
	var best_score := INF

	for i in 3:
		var axis := _gizmo_axis_dir(i)

		if gizmo_mode == GizmoMode.ROTATE:
			var hit = Plane(axis, axis.dot(o)).intersects_ray(ro, rd)
			if hit == null:
				continue
			var err := absf((hit as Vector3).distance_to(o) - s)
			if err < 0.1 * s and err < best_score:
				best = i
				best_score = err
		else:
			var r = _ray_axis(ro, rd, o, axis)
			if r == null or r.x < 0.0 or r.x > 1.2 * s or r.y < 0.0:
				continue
			var dist: float = (ro + rd * r.y).distance_to(o + axis * r.x)
			if dist < 0.12 * s and dist < best_score:
				best = i
				best_score = dist

	if best == -1:
		return false

	gizmo_axis = best
	gizmo_dragging = true
	g_origin = o
	g_axis_dir = _gizmo_axis_dir(best)
	g_start_basis = selected_object.global_basis
	g_start_scale = selected_object.scale
	g_ref = g_axis_dir.cross(Vector3.UP if absf(g_axis_dir.dot(Vector3.UP)) < 0.9 else Vector3.RIGHT).normalized()
	g_start_param = _gizmo_param(mouse)
	drag_before = _snapshot(selected_object)
	return true


func _gizmo_param(mouse: Vector2) -> float:
	var ro := project_ray_origin(mouse)
	var rd := project_ray_normal(mouse)

	if gizmo_mode == GizmoMode.ROTATE:
		var hit = Plane(g_axis_dir, g_axis_dir.dot(g_origin)).intersects_ray(ro, rd)
		if hit == null:
			return g_start_param
		var v: Vector3 = hit - g_origin
		return atan2(g_axis_dir.dot(g_ref.cross(v)), g_ref.dot(v))

	var r = _ray_axis(ro, rd, g_origin, g_axis_dir)
	return g_start_param if r == null else r.x


func gizmo_update(mouse: Vector2) -> void:
	if not is_instance_valid(selected_object):
		gizmo_dragging = false
		return

	var d := _gizmo_param(mouse) - g_start_param

	match gizmo_mode:
		GizmoMode.MOVE:
			d = snappedf(d, grid_size)
			selected_object.global_position = g_origin + g_axis_dir * d
		GizmoMode.ROTATE:
			d = snappedf(d, deg_to_rad(15.0))
			selected_object.global_basis = Basis(g_axis_dir, d) * g_start_basis
		GizmoMode.SCALE:
			d = snappedf(d, grid_size)
			var sc := g_start_scale
			sc[gizmo_axis] = maxf(0.05, sc[gizmo_axis] + d)
			selected_object.scale = sc

	PosUI.text = str(selected_object.position).replace("(", "").replace(")", "")
	RotUI.text = str(selected_object.rotation).replace("(", "").replace(")", "")
	SizeUI.text = str(selected_object.scale).replace("(", "").replace(")", "")



func snap(v: Vector3, step: float) -> Vector3:
	if step <= 0.0:
		return v
	return Vector3(snappedf(v.x, step), snappedf(v.y, step), snappedf(v.z, step))


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

	mat.uv1_triplanar = true
	mat.uv1_world_triplanar = true
	mat.uv1_scale = Vector3(uv1_scale, uv1_scale, uv1_scale)

	mat.albedo_color = color

	box.material_override = mat

	get_tree().current_scene.add_child(part)
	part.add_to_group("prt")
	
	part_count += 1
	part.name = "Part" + str(part_count)
	
	var newprt = baseobj.duplicate()
	newprt.text = part.name
	newprt.name = part.name
	
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
	newprt.name = part.name
	
	treeContainer.add_child(newprt)
	
	
	
	
	
	
func spawn_cylinder(pos: Vector3, size: Vector3, color: Color, rot: Vector3, isvisible: bool, cancollide: bool):
	var part = cylinder_scene.instantiate()

	part.position = pos
	part.scale = size
	part.rotation = rot
	part.visible = isvisible
	
	var box: CSGShape3D = part.get_node("PartMain")
	box.use_collision = cancollide

	var mat = StandardMaterial3D.new()

	mat.albedo_texture = default_tex
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST

	mat.uv1_triplanar = true
	mat.uv1_world_triplanar = true
	mat.uv1_scale = Vector3(uv1_scale, uv1_scale, uv1_scale)

	mat.albedo_color = color

	box.material_override = mat

	get_tree().current_scene.add_child(part)
	part.add_to_group("prt")
	
	part_count += 1
	part.name = "Cylinder" + str(part_count)
	
	var newprt = baseobj.duplicate()
	newprt.text = part.name
	newprt.name = part.name
	
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
	newprt.name = part.name
	
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
	newprt.name = part.name
	
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
	
	part_count += 1
	npc.name = "NPC" + str(part_count)
	
	var npctxt = baseobj.duplicate()
	npctxt.text = npc.name
	npctxt.name = npc.name
	
	treeContainer.add_child(npctxt)


func save_level(path: String, level_name: String, creator: String, description: String):
	var level_data = {
		"name": level_name,
		"creator": creator,
		"description": description,
		"version": 4,
		"parts": [],
		"spawner": [spawner.position.x, spawner.position.y, spawner.position.z],
		"scripts": scripts
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
		elif object.scene_file_path == cylinder_scene.resource_path:
			type = "cylinder"
		
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
			if object.name == "Players":
				continue
			
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

	scripts.clear()
	curr_script_name = ""
	codeUI.text = ""

	_clear_scripts()

	if level_data.has("scripts"):
		for script_name in level_data["scripts"]:
			scripts[script_name] = level_data["scripts"][script_name]
			_add_script_button(script_name)
	elif level_data.has("script"):
		scripts["Script1"] = level_data["script"]
		_add_script_button("Script1")

	if scripts.size() > 0:
		_open_script(scripts.keys()[0])

	if level_data == null:
		print("Invalid level!!")
		return

	for object in get_tree().get_nodes_in_group("prt"):
		if object.name != "Players":
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
			elif part_data["type"] == "cylinder":
				spawn_cylinder(
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
	var spawnerpointer = level_data.get("spawner", null)
	if spawnerpointer is Array and spawnerpointer.size() == 3:
		spawner.position = Vector3(spawnerpointer[0], spawnerpointer[1], spawnerpointer[2]) #please worrk please worrkkk pleawseeseeee
	elif spawnerpointer is String:
		var nums = spawnerpointer.replace("(", "").replace(")", "").split(",")
		if nums.size() == 3:
			spawner.position = Vector3(
				nums[0].strip_edges().to_float(),
				nums[1].strip_edges().to_float(),
				nums[2].strip_edges().to_float()
			)
			
			
			
			

func _make_selection_box() -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.948, 0.001, 0.948, 1.0)
	mat.no_depth_test = true

	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE
	mesh.material = mat

	selection_root = Node3D.new()
	selection_root.top_level = true
	selection_root.visible = false
	add_child(selection_root)

	for i in 12:
		var edge := MeshInstance3D.new()
		edge.mesh = mesh
		edge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		selection_root.add_child(edge)
		selection_edges.append(edge)


func _update_selection_box() -> void:
	if selection_root == null:
		return
	if not Global.is_builder or not is_instance_valid(selected_object):
		selection_root.visible = false
		return

	var main: Node3D = selected_object.get_node_or_null("PartMain")
	if main == null:
		main = selected_object.get_node_or_null("msg")

	var aabb := AABB(Vector3(-0.5, -0.5, -0.5), Vector3.ONE)
	var local_xf := Transform3D.IDENTITY
	if main is GeometryInstance3D or main is CSGShape3D:
		aabb = main.get_aabb()
		local_xf = main.transform

	var pad := Vector3.ONE * 0.02
	var fit := Transform3D(Basis.from_scale(aabb.size + pad), aabb.get_center())
	var xf: Transform3D = selected_object.global_transform * local_xf * fit

	var corners: Array[Vector3] = []
	for x in [-0.5, 0.5]:
		for y in [-0.5, 0.5]:
			for z in [-0.5, 0.5]:
				corners.append(xf * Vector3(x, y, z))

	var t := selection_thickness

	for i in 12:
		var a: Vector3 = corners[boxEdges[i][0]]
		var b: Vector3 = corners[boxEdges[i][1]]
		var dir := b - a
		var length := dir.length()
		if length < 0.0001:
			selection_edges[i].visible = false
			continue
		selection_edges[i].visible = true

		var z_axis := dir / length
		var up := Vector3.UP if absf(z_axis.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
		var x_axis := up.cross(z_axis).normalized()
		var y_axis := z_axis.cross(x_axis)

		var basis := Basis(x_axis * t, y_axis * t, z_axis * (length + t))
		selection_edges[i].transform = Transform3D(basis, (a + b) * 0.5)

	selection_root.visible = true



func loadLoadDialog():
	var folder = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	var correctdir: String = folder.path_join("Bubbol Builder")
	loaddialog.current_dir = correctdir
	loaddialog.popup_centered()
	is_coding = true
	global_position = spawner.position + Vector3(0, 2, 5)
	
	
func loadSaveDialog():
	var folder = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	var correctdir: String = folder.path_join("Bubbol Builder")
	savedialog.current_dir = correctdir
	savedialog.popup_centered()
	is_coding = true
	global_position = spawner.position + Vector3(0, 2, 5)
	
	





func _ready():
	
	PosUI.text_submitted.connect(_on_PosUI_text_submitted)
	RotUI.text_submitted.connect(_on_RotUI_text_submitted)
	SizeUI.text_submitted.connect(_on_SizeUI_text_submitted)
	TxtObjUI.text_submitted.connect(_on_TxtObjUI_text_submitted)
	canseeUI.toggled.connect(_on_canseeUI_toggled)
	cancollideUI.toggled.connect(_on_cancollideUI_toggled)
	spawnPartUI.pressed.connect(_on_spawnPartUI_pressed)
	spawnBillboardUI.pressed.connect(_on_Billboard_pressed)
	spawnTextUI.pressed.connect(_on_Text_pressed)
	spawnSphereUI.pressed.connect(_on_spawnSphereUI_pressed)
	spawnNPCUI.pressed.connect(_on_spawnNPCUI_pressed)
	spawnCylinderUI.pressed.connect(_on_cylinder_pressed)
	codeUI.text_changed.connect(_on_codeUI_text_changed)
	enterScriptUI.pressed.connect(_on_spawnScriptUI_pressed)
	codeSaveUI.pressed.connect(_on_codeSaveUI_pressed)
	spawnScriptUI.pressed.connect(new_script)
	deleteScriptUI.pressed.connect(delete_current_script)
	loadLevelUI.pressed.connect(load_pressed)
	newLevelUI.pressed.connect(new_pressed)
	starterLevelUI.pressed.connect(starter_pressed)
	MOVE.pressed.connect(move_pressed)
	ROT.pressed.connect(rot_pressed)
	SCALE.pressed.connect(scale_pressed)
	
	if not player.is_multiplayer_authority():
		current = false
		set_process(false)
		set_process_unhandled_input(false)
		return

	current = true
	top_level = true
	follow_pos = player.global_position + Vector3.UP * height
	Global.builder_toggled.connect(_on_builder_toggled)
	global_position = spawner.position + Vector3(0, 2, 5)
	_make_selection_box()
	_make_gizmo()

	



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
			drag_before = _snapshot(selected_object)
			dragging_object = true
			
			#var mainObj = object.get_node("PartMain")
			#var mat = mainObj.material_override
			
			#mat.emission_enabled = true
			#mat.emission = Color(0.474, 0.474, 0.474, 1.0)
			#mat.emission_energy_multiplier = 2.0
			
			drag_distance = global_position.distance_to(selected_object.global_position)
			
			#var target_pos = ray_origin + ray_direction * drag_distance
			#target_pos = snap(target_pos, grid_size)
			#selected_object.global_position = target_pos

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
		
		
		
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Z and (event.ctrl_pressed or event.meta_pressed) \
				and Global.is_builder and not is_coding:
			undo()
			get_viewport().set_input_as_handled()
			return
			
		if event.keycode == KEY_N and Global.is_builder and not is_coding:
			gizmo_mode = ((gizmo_mode + 1) % 3) as GizmoMode
			get_viewport().set_input_as_handled()
			return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if gizmo_try_begin(event.position):
					get_viewport().set_input_as_handled()
					return
				select_object(event.position)
			else:
				if gizmo_dragging:
					if not _same_transform(drag_before, _snapshot(selected_object)):
						push_undo(drag_before)
					drag_before = {}
					gizmo_dragging = false
					return
				
				
				#var mainObj = selected_object.get_node("PartMain")
				#var mat = mainObj.material_override
			
				#mat.emission_enabled = false
				drag_before = {}
				dragging_object = false
				

		elif event.button_index == MOUSE_BUTTON_RIGHT:
			rotating = event.pressed

		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = clamp(zoom - zoom_speed, min_zoom, max_zoom)

		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = clamp(zoom + zoom_speed, min_zoom, max_zoom)
			
	elif event is InputEventMouseMotion:
		if gizmo_dragging:
			gizmo_update(event.position)
		elif rotating:
			yaw -= event.relative.x * sensitivity
			pitch = clamp(pitch - event.relative.y * sensitivity, -1.4, 1.4)

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
		
	_update_selection_box()
	_update_gizmo()
		
	if Global.is_builder and not was_builder:
		global_position = spawner.position + Vector3(0, 2, 5)
	was_builder = Global.is_builder
	
	if Global.is_builder and inMenuUi:
		$BuilderStarterUI.visible = true
	else:
		$BuilderStarterUI.visible = false

	if Global.is_builder and can_use_builder:
		
		DiscordRPC.details = "In Bubbol! Builder"
		DiscordRPC.refresh()
		
		studioUi.visible = true
		
		if get_viewport().gui_get_focus_owner() is LineEdit:
			return
		
		
		if dragging_object and selected_object:
			
			await get_tree().create_timer(0.5).timeout
			
			if dragging_object and selected_object:
				
				var mouse_pos = get_viewport().get_mouse_position()

				var ray_origin = project_ray_origin(mouse_pos)
				var ray_direction = project_ray_normal(mouse_pos)

				selected_object.global_position = (
					ray_origin + ray_direction * drag_distance
				)
			
				var target_pos = ray_origin + ray_direction * drag_distance
				target_pos = snap(target_pos, grid_size)
				selected_object.global_position = target_pos
			
			
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
		if Input.is_action_just_pressed("scale_part") and not is_coding:
			if selected_object != null:
				selected_object.scale += Vector3(1, 1, 1)
			else:
				Global.part_size += 1
		if Input.is_action_just_pressed("descale_part") and not is_coding:
			if selected_object != null:
				selected_object.scale -= Vector3(1, 1, 1)
			else:
				Global.part_size -= 1
		if Input.is_action_just_pressed("toggle_use_texture") and not is_coding:
			uv1_scale += 1
		if Input.is_action_just_pressed("kill_part") and not is_coding: #NO, THIS DOES NOT ADD LIKE A KILLBRICK THING, IT JUST MURDERS THE PART!!
			if selected_object != null:
				var obj_ui = treeContainer.find_child(selected_object.name, true, false)
				if obj_ui:
					obj_ui.queue_free()
				selected_object.queue_free()
				part_count -= 1
		if Input.is_action_just_pressed("rotate_part") and not is_coding:
			if selected_object != null:
				selected_object.rotate_x(10)
				
		if Input.is_action_just_pressed("scale_up") and not is_coding:
			if selected_object != null:
				selected_object.scale += Vector3(0, 1, 0)
		if Input.is_action_just_pressed("scale_down") and not is_coding:
			if selected_object != null:
				selected_object.scale += Vector3(0, -1, 0)
				
		if Input.is_action_just_pressed("scale_x") and not is_coding:
			if selected_object != null:
				selected_object.scale += Vector3(1, 0, 0)
		if Input.is_action_just_pressed("unscale_x") and not is_coding:
			if selected_object != null:
				selected_object.scale += Vector3(-1, 0, 0)
				
		if Input.is_action_just_pressed("scale_z") and not is_coding and not Input.is_key_pressed(KEY_CTRL):
			if selected_object != null:
				selected_object.scale += Vector3(0, 0, 1)
		if Input.is_action_just_pressed("unscale_z") and not is_coding:
			if selected_object != null:
				selected_object.scale += Vector3(0, 0, -1)
		if Input.is_action_just_pressed("duplicate") and not is_coding:
			if selected_object != null:
				var clone = selected_object.duplicate()
				get_tree().current_scene.add_child(clone)
		if Input.is_key_pressed(KEY_F):
			if selected_object != null:
				position = selected_object.position
				selected_object = null
				
		if Input.is_action_just_pressed("save") and not is_coding:
			loadSaveDialog()
			#can_use_builder = false
		if Input.is_action_just_pressed("load_level"):
			loadLoadDialog()
			#can_use_builder = false
				
				
		if Input.is_key_pressed(KEY_1):
			if selected_object != null:
				var box: CSGShape3D = selected_object.get_node("PartMain")

				var mat = StandardMaterial3D.new()

				mat.albedo_texture = default_tex
				mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST

				mat.albedo_color = Color.WHITE
				
				mat.uv1_triplanar = true
				mat.uv1_world_triplanar = true
				mat.uv1_scale = Vector3(uv1_scale, uv1_scale, uv1_scale)

				box.material_override = mat
		if Input.is_key_pressed(KEY_2):
			if selected_object != null:
				var box: CSGShape3D = selected_object.get_node("PartMain")

				var mat = StandardMaterial3D.new()

				mat.albedo_texture = default_tex
				mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST

				mat.albedo_color = Color.BLACK
				
				mat.uv1_triplanar = true
				mat.uv1_world_triplanar = true
				mat.uv1_scale = Vector3(uv1_scale, uv1_scale, uv1_scale)

				box.material_override = mat
		if Input.is_key_pressed(KEY_3):
			if selected_object != null:
				var box: CSGShape3D = selected_object.get_node("PartMain")

				var mat = StandardMaterial3D.new()

				mat.albedo_texture = default_tex
				mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST

				mat.albedo_color = Color(0.584, 1.0, 0.416, 1.0)
				
				mat.uv1_triplanar = true
				mat.uv1_world_triplanar = true
				mat.uv1_scale = Vector3(uv1_scale, uv1_scale, uv1_scale)

				box.material_override = mat
		if Input.is_key_pressed(KEY_4):
			if selected_object != null:
				var box: CSGShape3D = selected_object.get_node("PartMain")

				var mat = StandardMaterial3D.new()

				mat.albedo_texture = default_tex
				mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST

				mat.albedo_color = Color(0.0, 0.0, 1.0, 1.0)
				
				mat.uv1_triplanar = true
				mat.uv1_world_triplanar = true
				mat.uv1_scale = Vector3(uv1_scale, uv1_scale, uv1_scale)

				box.material_override = mat
		if Input.is_key_pressed(KEY_5):
			if selected_object != null:
				var box: CSGShape3D = selected_object.get_node("PartMain")

				var mat = StandardMaterial3D.new()

				mat.albedo_texture = default_tex
				mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST

				mat.albedo_color = Color(1.0, 0.678, 0.384, 1.0)

				mat.uv1_triplanar = true
				mat.uv1_world_triplanar = true
				mat.uv1_scale = Vector3(uv1_scale, uv1_scale, uv1_scale)

				box.material_override = mat
		if Input.is_key_pressed(KEY_6):
			if selected_object != null:
				var box: CSGShape3D = selected_object.get_node("PartMain")

				var mat = StandardMaterial3D.new()

				mat.albedo_texture = default_tex
				mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST

				mat.albedo_color = Color(1.0, 0.0, 0.384, 1.0)
				
				mat.uv1_triplanar = true
				mat.uv1_world_triplanar = true
				mat.uv1_scale = Vector3(uv1_scale, uv1_scale, uv1_scale)

				box.material_override = mat
				
		if Input.is_key_pressed(KEY_7):
			if selected_object != null:
				var box: CSGShape3D = selected_object.get_node("PartMain")

				var mat = StandardMaterial3D.new()

				mat.albedo_texture = default_tex
				mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST

				mat.albedo_color = Color(1.0, 0.933, 0.0, 1.0)
				
				mat.uv1_triplanar = true
				mat.uv1_world_triplanar = true
				mat.uv1_scale = Vector3(uv1_scale, uv1_scale, uv1_scale)

				box.material_override = mat
				
		if Input.is_key_pressed(KEY_8):
			if selected_object != null:
				var box: CSGShape3D = selected_object.get_node("PartMain")

				var mat = StandardMaterial3D.new()

				mat.albedo_texture = default_tex
				mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST

				mat.albedo_color = Color(0.446, 0.466, 0.521, 1.0)
				
				mat.uv1_triplanar = true
				mat.uv1_world_triplanar = true
				mat.uv1_scale = Vector3(uv1_scale, uv1_scale, uv1_scale)

				box.material_override = mat
				

		if Input.is_action_just_pressed("part") and not is_coding:
			spawn_part(global_position + Vector3(0, -2, 0), Vector3(Global.part_size, Global.part_size, Global.part_size), Color(1.0, 1.0, 1.0, 1.0), Vector3(0, 0, 0), true, true)
			
		if Input.is_action_just_pressed("sphere") and not is_coding:
			spawn_sphere(global_position + Vector3(0, -2, 0), Vector3(Global.part_size, Global.part_size, Global.part_size), Color(1.0, 1.0, 1.0, 1.0), Vector3(0, 0, 0), true, true)
		if Input.is_action_just_pressed("billboard3d") and not is_coding:
			spawn_billboard(global_position + Vector3(0, -2, 0), Vector3(Global.part_size, Global.part_size, Global.part_size), "Message")
		if Input.is_action_just_pressed("text3d") and not is_coding:
			spawn_text3d(global_position + Vector3(0, -2, 0), Vector3(Global.part_size, Global.part_size, Global.part_size), "Message")
		if Input.is_action_just_pressed("npc") and not is_coding:
			spawn_npc(global_position + Vector3(0, -2, 0), Vector3(Global.part_size, Global.part_size, Global.part_size), Vector3(0, 0, 0), true, true)

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
	is_coding = false
	
	




func _on_load_file_selected(path: String) -> void:
	print("gonna load. path: " + path)
	load_level(path)
	can_use_builder = true
	var lvl_title: String = path.get_file()
	DiscordRPC.state = "Building " + lvl_title
	DiscordRPC.refresh()
	is_coding = false
	
	


func _on_save_canceled() -> void:
	can_use_builder = true
	is_coding = false
	
	
	
	
	
	
func _on_load_canceled() -> void:
	can_use_builder = true
	is_coding = false
	
	
	
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
	
	
	
	
	
func _on_Billboard_pressed() -> void:
	spawn_billboard(global_position + Vector3(0, -2, 0), Vector3(Global.part_size, Global.part_size, Global.part_size), "Message")
	
	
	
func _on_Text_pressed() -> void:
	spawn_text3d(global_position + Vector3(0, -2, 0), Vector3(Global.part_size, Global.part_size, Global.part_size), "Message")
	
	
	
	
	
func _on_cylinder_pressed() -> void:
	spawn_cylinder(position + Vector3(0, -2, 0), Vector3(Global.part_size, Global.part_size, Global.part_size), Color(1.0, 1.0, 1.0, 1.0), Vector3(0, 0, 0), true, true)
	
	
	
	
	
	
func _on_codeUI_text_changed(newcode) -> void:
	currScript = newcode
	
	
	
	
func _on_spawnScriptUI_pressed() -> void:
	if scripts.is_empty():
		new_script()
	codeUI.visible = not codeUI.visible
	is_coding = true
	Global.is_coding = true
	
	
	
	
	
	
func _on_codeSaveUI_pressed() -> void:
	_commit_current_script()
	codeUI.visible = not codeUI.visible
	is_coding = false
	Global.is_coding = false
	
	
func load_pressed() -> void:
	loadLoadDialog()
	inMenuUi = false
	
	
func new_pressed() -> void:
	inMenuUi = false
	
	
	
func starter_pressed() -> void:
	load_level("res://assets/defaultLevels/tutorial_level.json")
	inMenuUi = false
	
	
	
func move_pressed() -> void:
	gizmo_mode = 0
	
func rot_pressed() -> void:
	gizmo_mode = 1
	
func scale_pressed() -> void:
	gizmo_mode = 2
	
	
	
	
func _on_builder_toggled(is_builder: bool) -> void:
	if is_builder:
		global_position = spawner.position + Vector3(0, 2, 5)
		
		var clones = get_tree().get_nodes_in_group("_CLONE")
		
		for clone in clones:
			clone.process_mode = PROCESS_MODE_DISABLED
			clone.queue_free()
			
		return
		
	_commit_current_script()
	for script_name in scripts:
		BubbolscriptRuntime.run_script(scripts[script_name], world)
	
	
	
	
	
var script_buttons := {}

func _commit_current_script():
	if curr_script_name != "":
		scripts[curr_script_name] = codeUI.text
		codeUI.placeholder_text = "Type code here! (You're editing " + curr_script_name + ")"

func _add_script_button(script_name: String):
	var btn = baseobj.duplicate()
	btn.text = script_name
	btn.icon = load("res://textures/studio/script.png")
	btn.name = script_name
	btn.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.double_click and e.pressed and e.button_index == MOUSE_BUTTON_LEFT: 
			codeUI.visible = not codeUI.visible
			is_coding = true
			Global.is_coding = true
			curr_script_name = btn.name
		elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT: 
			_open_script(script_name)
	)
			
	treeContainer.add_child(btn)
	script_buttons[script_name] = btn

func _open_script(script_name: String):
	_commit_current_script()
	curr_script_name = script_name
	codeUI.text = scripts[script_name]
	
	for n in script_buttons:
		script_buttons[n].modulate = Color.DARK_GRAY
	script_buttons[script_name].modulate = Color(1.0, 1.0, 1.0, 1.0)

func new_script():
	var i = scripts.size() + 1
	while scripts.has("Script" + str(i)):
		i += 1
	var script_name = "Script" + str(i)
	_commit_current_script()
	scripts[script_name] = ""
	_add_script_button(script_name)
	_open_script(script_name)

func delete_current_script():
	if curr_script_name == "":
		return
	script_buttons[curr_script_name].queue_free()
	script_buttons.erase(curr_script_name)
	scripts.erase(curr_script_name)
	curr_script_name = ""
	codeUI.text = ""
	#codeUI.visible = false #what? adding this just made it impossible to playtest if you delete a script :sob:
	if scripts.size() > 0:
		_open_script(scripts.keys()[0])

func _clear_scripts():
	for n in script_buttons:
		script_buttons[n].queue_free()
	script_buttons.clear()
	scripts.clear()
	curr_script_name = ""
	codeUI.text = ""
	
	
	
	
	

func push_undo(entry: Dictionary) -> void:
	if loading:
		return
	undo_stack.append(entry)
	if undo_stack.size() > max_undo:
		undo_stack.clear()

func _snapshot(obj: Node3D) -> Dictionary:
	return {"type": "transform", "node": obj,
			"pos": obj.position, "rot": obj.rotation, "scale": obj.scale}

func _same_transform(a: Dictionary, b: Dictionary) -> bool:
	return a["pos"] == b["pos"] and a["rot"] == b["rot"] and a["scale"] == b["scale"]

func push_transform_undo(obj: Node3D) -> void:
	if obj != null:
		push_undo(_snapshot(obj))

func undo() -> void:
	if undo_stack.is_empty():
		return
	var e: Dictionary = undo_stack.pop_back()

	match e["type"]: #more to be added soon
		"transform":
			var n: Node3D = e["node"]
			if is_instance_valid(n) and n.is_inside_tree():
				n.position = e["pos"]
				n.rotation = e["rot"]
				n.scale = e["scale"]
				if n == selected_object:
					PosUI.text = str(n.position).replace("(", "").replace(")", "")
					RotUI.text = str(n.rotation).replace("(", "").replace(")", "")
					SizeUI.text = str(n.scale).replace("(", "").replace(")", "")
