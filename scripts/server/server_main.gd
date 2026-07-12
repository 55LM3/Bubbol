extends Node3D

@export var player_scene: PackedScene
@export var part_scene: PackedScene
var peer := ENetMultiplayerPeer.new()

@onready var spawner := $MultiplayerSpawner
@onready var partSpawner = $PartSpawner
@onready var players := $Players
#@onready var desiredUsr := $CanvasLayer/CenterContainer/VBoxContainer/Username
@onready var disconnectMsg = $disconnected
@onready var chatBox = $chat
@onready var loadMenu = $Load
@onready var signUp = $signup
@onready var layer = $CanvasLayer
@onready var logoutButton := $CanvasLayer/CenterContainer/VBoxContainer/LOGOUT

const DEFAULT_TEX = preload("res://textures/world/object/BubbolDefaultTexture.png")

var plrUsr = "Username"
var playit_address := "147.185.221.212:51855" #ip for server. it uses my laptop atm as the server
var usr_db : SQLite

var maxUsernameLength = 40



#TODO
#make usernames automatically be your logged in user account instead of previous version that let you choose username every time (DONE!!)
#less brittle multiplayer code and higher security (coming in like a future update, im currently just focusing on the groundwork and foundation of accounts)
#multiple server instances, to allow players to be in different games
#fix login (DONE!!)
#auto login (DONE!!)


func _ready():
	spawner.spawn_function = _spawn_user
	partSpawner.spawn_function = _spawn_part
	
	if DisplayServer.get_name() == "headless":
		peer.create_server(6666)
		multiplayer.multiplayer_peer = peer
		load_level("BUBBOL-MAPS/1.json")
		setup_plr_db()
		DiscordRPC.clear(true)
	else:
		connect_to_server()
		
	
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	multiplayer.connected_to_server.connect(func():
		print("Connected to server!")
		loginWithCreds()
		#submit_username.rpc_id(1, plrUsr)
	)

	multiplayer.connection_failed.connect(func():
		print("Connection failed")
	)

	multiplayer.server_disconnected.connect(func():
		print("Server disconnected")
		disconnectMsg.visible = true
	)


func connect_to_server():
	var parts = playit_address.split(":")
	var host_domain = parts[0]
	var host_port = int(parts[1])

	print("Connecting to ", host_domain, ":", host_port)

	peer.create_client(host_domain, host_port)
	multiplayer.multiplayer_peer = peer


func setup_plr_db():
	var exe_dir : String = OS.get_executable_path().get_base_dir()
	
	var db_path : String = exe_dir.path_join("BUBBOL-DB/bubbolGame.db")
	
	usr_db = SQLite.new()
	usr_db.path = db_path
	usr_db.open_db()
	print("Player Database successfully loaded at path: ", db_path)
	
	var player_table = {
	"username": {"data_type": "text", "primary_key": true, "not_null": true},
	"password_hash": {"data_type": "text", "not_null": true},
}
	usr_db.create_table("players", player_table)




func _on_join_pressed():
	submit_username.rpc_id(1, plrUsr)
	loadMenu.visible = false
	layer.visible = false
	setWindowTitle("Playing a game")
	


	

func _on_peer_connected(id):
	print("User joined with ID:", id)
	loadMenu.visible = false
	pass

func _on_peer_disconnected(id):
	if not multiplayer.is_server():
		return
		
	print("User left with ID: ", id)
	var node = players.get_node_or_null(str(id))
	
	if node:
		var username_leaving = node.username if "username" in node else "A player"
		
		server_message(username_leaving + " has left the game!")
		
		node.queue_free()


func _spawn_user(data: Variant) -> Node:
	var id = data[0]
	var username_to_assign = data[1]
	
	var player = player_scene.instantiate()
	player.name = str(id)
	player.username = username_to_assign
	if multiplayer.is_server():
		server_message(username_to_assign + " has Joined the Game!")
	
	return player


func _spawn_part(data: Variant) -> Node:
	var part = part_scene.instantiate()

	part.position = data.position
	part.scale = data.scale
	part.rotation = data.rotation

	var box: CSGBox3D = part.get_node("PartMain")

	var mat = StandardMaterial3D.new()
	
	mat.albedo_texture = DEFAULT_TEX
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	
	mat.albedo_color = Color(
		data.color[0],
		data.color[1],
		data.color[2]
	)

	box.material_override = mat

	print("Applied color: ", mat.albedo_color)

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
	
	


func setWindowTitle(windowName : String):
	get_window().title = "Bubbol! Client - " + windowName
	DiscordRPC.details = windowName
	DiscordRPC.refresh()



func load_level(path: String):
	if not multiplayer.is_server():
		return

	var file = FileAccess.open(path, FileAccess.READ)
	var sender = multiplayer.get_remote_sender_id()

	if file == null:
		print("No level found its a null level, wrong path: ", path)
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



func enter_menu():
	signUp.visible = false
	layer.visible = true
	loadMenu.visible = true


@rpc("any_peer", "reliable")
func submit_username(client_name):
	if not multiplayer.is_server():
		return

	var sender_id = multiplayer.get_remote_sender_id()

	spawner.spawn([sender_id, client_name])
	
	

@rpc("authority", "reliable")
func registration_success(username: String, password: String):
	print("Account created!!!")
	plrUsr = username
	chatBox.username = plrUsr
	enter_menu()
	save_creds(username, password)

@rpc("authority", "reliable")
func registration_failed(reason: String):
	print("Registration failed:", reason)
	
	
@rpc("authority", "reliable")
func login_success(username: String, password: String):
	print("logged into account!!!")
	plrUsr = username
	chatBox.username = plrUsr
	enter_menu()
	save_creds(username, password)

@rpc("authority", "reliable")
func login_failed(reason: String):
	print("Login failed:", reason)


func save_creds(username: String, password: String):
	var file = FileAccess.open("credentials.txt", FileAccess.WRITE)
	
	if file:
		file.store_line(username)
		file.store_line(password)
	else:
		print("SOMETHING WENT WRONG!!! CRITICAL!! USER GAME MAY BE CORRUPTED!!!!!")



	
@rpc("any_peer", "reliable")
func register(username: String, password: String):
	print("REGISTER RECEIVED:", username)
	
	if !multiplayer.is_server():
		return

	var sender = multiplayer.get_remote_sender_id()

	var rows = usr_db.select_rows(
		"players",
		"username = '%s'" % username,
		["username"]
	)

	if rows.size() > 0:
		registration_failed.rpc_id(sender, "Username already exists!!")
		return
		
	var regex = RegEx.new()
	regex.compile("^[A-Za-z0-9_]{3,40}$")

	if regex.search(username) == null:
		registration_failed.rpc_id(sender, "Username must be 3-40 letters numbers, or underscores!!!!")
		return

	var hash = password.sha256_text()
	plrUsr = username

	usr_db.insert_row("players", {
		"username": username,
		"password_hash": hash
	})

	registration_success.rpc_id(sender, username, password)
	save_creds(username, password)


@rpc("any_peer", "reliable")
func login(username: String, password: String):
	if !multiplayer.is_server():
		return
		
	
	var rows = usr_db.select_rows(
	"players",
	"username = '%s'" % username,
	["password_hash"]
)

	var sender = multiplayer.get_remote_sender_id()

	if rows.is_empty():
		#print("Username or password incorrect!!")
		login_failed.rpc_id(sender, "Username or password incorrect!!")
		return
		
	
	var stored_hash = rows[0]["password_hash"]

	if stored_hash != password.sha256_text():
		print("Username or password incorrect!!")
		login_failed.rpc_id(sender, "Username or password incorrect!!")
		return
		
	login_success.rpc_id(sender, username, password)

func loginWithCreds():
	var file = FileAccess.open("credentials.txt", FileAccess.READ)
	
	if file == null:
		#file = FileAccess.open("credentials.txt", FileAccess.WRITE)
		return #im just returning for now i dont want any weird issues to fix atm
		
	
	var usrname = file.get_line()
	print(usrname)
	
	var password = file.get_line() #NOT HASHED, login function automatically hashes it!
	print(password)
	
	login.rpc_id(1, usrname, password)
	
	
func server_message(text: String):
	chatBox.send_chat_message.rpc("[SERVER]: " + text)


func _on_logout_pressed() -> void:
	var creds = "credentials.txt"
	var error = DirAccess.remove_absolute(creds)
	get_tree().quit()
