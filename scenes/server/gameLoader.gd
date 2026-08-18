extends Node3D

@export var player_scene: PackedScene
@export var part_scene: PackedScene

@onready var partSpawner: MultiplayerSpawner = $PartSpawner
@onready var plrSpawner: MultiplayerSpawner = $PlrSpawner


var level_loaded := false

const DEFAULT_TEX = preload("res://textures/world/object/BubbolDefaultTexture.png")


func _ready():
	plrSpawner.spawn_function = _spawn_user
	partSpawner.spawn_function = _spawn_part





func _spawn_part(data: Variant) -> Node:
	var part = part_scene.instantiate()

	part.position = data["position"]
	part.scale = data["scale"]
	part.rotation = data["rotation"]

	var box: CSGBox3D = part.get_node("PartMain")

	var mat = StandardMaterial3D.new()

	mat.albedo_texture = DEFAULT_TEX
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST

	mat.albedo_color = Color(
		data["color"][0],
		data["color"][1],
		data["color"][2]
	)

	box.material_override = mat

	return part



func spawn_part(pos: Vector3, size: Vector3, color: Color, rot: Vector3):
	if not multiplayer.is_server():
		return

	partSpawner.spawn({
		"position": pos,
		"scale": size,
		"color": [
			color.r,
			color.g,
			color.b
		],
		"rotation": rot
	})




func load_level(ID: String):
	if not multiplayer.is_server():
		return

	var file = FileAccess.open("BUBBOL-MAPS/" + ID, FileAccess.READ)

	if file == null:
		print("No level found its a null level, nonexistant ID: ", ID)
		return

	var json_text = file.get_as_text()
	var level_data = JSON.parse_string(json_text)

	if level_data == null:
		print("Invalid JSON data")
		return

	print("loading up level: ", level_data["name"])
	print("level created by: ", level_data["creator"])
	print("level description: ", level_data["description"])

	for part_data in level_data["parts"]:
		var position = Vector3(
			part_data["position"][0],
			part_data["position"][1],
			part_data["position"][2]
		)

		var scale = Vector3(
			part_data["scale"][0],
			part_data["scale"][1],
			part_data["scale"][2]
		)
		
		var color = Color(
			part_data["color"][0],
			part_data["color"][1],
			part_data["color"][2]
		)
		
		var rotation = Vector3(
			part_data["rotation"][0],
			part_data["rotation"][1],
			part_data["rotation"][2]
		)

		spawn_part(position, scale, color, rotation)








func _spawn_user(data: Variant) -> Node:
	var id = data[0]
	var client_name = data[1]

	var player = player_scene.instantiate()

	player.name = str(id)
	player.username = client_name

	return player




func spawn_plr(sender_id, client_name):
	if not multiplayer.is_server():
		return

	plrSpawner.spawn([sender_id, client_name])
