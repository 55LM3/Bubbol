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
@onready var layer = $menu
@onready var logoutButton := $menu/LOGOUT


const sync = preload("res://scripts/server/SyncHandler.gd")
var sync_handler: SyncHandler

const GameManager = preload("res://scripts/server/GameManager.gd")

var game_manager: Node

const DEFAULT_TEX = preload("res://textures/world/object/BubbolDefaultTexture.png")

var plrUsr = "Username"
var playit_address := "147.185.221.212:51855" #ip for server. it uses my laptop atm as the server
var usr_db : SQLite

var maxUsernameLength = 40


#are they called worlds games or levels? idk the code is very inconsistent i use them all :/ just depends on what im feeling atm
#i'll try to stick with games but dont count on it


#TODO
#make usernames automatically be your logged in user account instead of previous versions that let you choose username every time (DONE!!)
#less brittle multiplayer code and higher security (coming in like a future update, im currently just focusing on the groundwork and foundation of accounts)
#multiple server instances, to allow players to be in different games (Working on it!)
#fix login (DONE!!)
#auto login (DONE!!)
#GENUINELY WHY THE FUCK DO THE GAMES NOT LOAD I AM SO FUCKING MAD I AM FUCKING GOING TO FUCKING SCREAM I HAVE A FUCKING DAY LEFT TO RELEASE EVERY FUCKING THING AND I FUCKING HAVENT EVEVN FUCKING FINISHED FUCKING GAME LOADING YET OH MY FUCKING FUCKING GOD
#THERES NOT A SINGLE FUCKING  REASON WHY IT FUCKING WONT FUCKING WORK I AM FUCKING SO ANNOYED I AM NEVER FUCKING TOUCHING GODOT OR FUCKING NETWORKING IN MY LIFE GENUINELY FUCK THIS ABSOLUTE FUCKING GODDAMN FUCKING PIECE OF HORNY SHIT WHAT THE FUCK AM I FUCKING TYPING OH MY FUCKING GOD IS THE FUCKING CODE FUCKING RETARDED OR FUCKING SOME SHIT? BECAUSE I AM SO FUCKING ANNOYED THERES ABSOLUTELY NO FUCKING REASON WHY IT SHOULS FUCKING BE DOINTH THIS FUCKING SHIT OMH YGDF
#ok its fixed
#HOLY SHIT I HAVE 5 FUCKING MINUTES TO RELEASZE EVERYTHING WHY THE FUCK DOES IT LOAD YOU INTO THE MAP NODE AND NOT THE WORLD NODE OR SUM SHI
#ok the upd is released BUT THERES SO MANY FUCKING BUGS LIKE WTF WHY WHEN I RELOAD THE GAME IM FUCKING LOGGED OUT AND CANT LOGIN OR CREATE AN ACCOUNT
#I AM ALSO PLAYING AS SOME PPL ON THEIR ACC WHEN THEY CREATE AN ACCOUNT FOR SOME STUPID REASON
#AND THERES JUST SO MUCH MORE BUGS LIKE SOME PEOPLE CANT EVEN CREATE AN ACC OR LOGIN FOR SOME DUMB FUCKING REASON

#3. fucking. WEEKS. OF FUCKING FUCKING BUGS. OH MY FUCKING GOD WHAT THE FUCKING HELL? THIS STUPID BUG.

#HUGE THING I NEED TO DO: FUCKING FIX THE BUG WHERE IF YOU EXIT THE GAME AND RELOAD THE CLIENT, YOU FUCKING DONT EVEN CONNECT TO THE SERVER WHAT THE HELL???

func _ready():
	sync_handler = sync.new()
	add_child(sync_handler)

	game_manager = GameManager.new()
	add_child(game_manager)


	spawner.spawn_function = _spawn_user
	partSpawner.spawn_function = _spawn_part

	if DisplayServer.get_name() == "headless" or DisplayServer.get_name() == "hds":
		peer.create_server(6666)
		multiplayer.multiplayer_peer = peer

		#load_level("BUBBOL-MAPS/1.json")
		setup_plr_db()
		DiscordRPC.clear(true)
	else:
		connect_to_server()
		
	
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	multiplayer.connected_to_server.connect(func():

		print("about to login")
		loginWithCreds()

		#print("About to request games...")
		#ask_serv_for_games()

		print("finished startup reqs")
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




#func _on_join_pressed():
	#submit_username.rpc_id(1, plrUsr)
	#loadMenu.visible = false
	#layer.visible = false
	#setWindowTitle("Playing a game")
	


	

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
	
	
func spawn_part(pos: Vector3, size: Vector3, color: Color, rot: Vector3): #dont use this use the other thingy now
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



func load_level(path: String): #like before dont use this shit you use the other thingy now too
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

	#spawner.spawn([sender_id, client_name])
	game_manager.spawn_plr(sender_id, client_name)
	
	

@rpc("authority", "reliable")
func registration_success(username: String, password: String):
	print("Account created!!!")
	plrUsr = username
	chatBox.username = plrUsr
	enter_menu()
	save_creds(username, password)
	ask_serv_for_games()

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
	ask_serv_for_games()

@rpc("authority", "reliable")
func login_failed(reason: String):
	print("Login failed:", reason)


func save_creds(username: String, password: String):
	var file = FileAccess.open("user://credentials.txt", FileAccess.WRITE)
	
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
	#save_creds(username, password) #wtf what was the point of this


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
	var file = FileAccess.open("user://credentials.txt", FileAccess.READ)
	
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


#func _on_logout_pressed() -> void:
	#var path = ProjectSettings.globalize_path("user://credentials.txt")
	#DirAccess.remove_absolute(path)
	#get_tree().quit()









const BUTTON_TEMPLATE = preload("res://scenes/client/ui/base_button.tscn")

@onready var games_list_container = $menu/Games

@rpc("any_peer", "call_remote", "reliable")
func recieve_games_server(all_games: Array) -> void:
	print("Successfully received data for ", all_games.size(), " maps!")
	
	for child in games_list_container.get_children():
		child.queue_free()
		
	for map_data in all_games:
		var map_button = BUTTON_TEMPLATE.instantiate()
		
		var map_name = map_data.get("name", "Unknown Title")
		var creator_name = map_data.get("creator", "Unknown Creator")
		var target_file = map_data.get("file_name", "")
		
		var visual_text = "Join " + map_name
		
		if map_button is Button:
			map_button.text = visual_text
			map_button.get_node("Creator").text = "By " + creator_name
			map_button.name = target_file #so it will be like 1.json NOT just "1"
		
		map_button.pressed.connect(func():
			_on_map_button_selected(target_file)
		)
		
		games_list_container.add_child(map_button)
		print("added child button")



@rpc("authority", "reliable")
func create_client_world(world_id: String, client_name: String) -> void:
	if multiplayer.is_server():
		return

	print("CLIENT: Creating world ", world_id)

	var world = game_manager.create_client_world(world_id)

	if world == null:
		print("CLIENT: FAILED to create world!")
		return

	print("CLIENT: World created at ", world.get_path())

	world_ready.rpc_id(1, world_id, client_name)
	
	
	
	
@rpc("any_peer", "reliable")
func world_ready(world_id: String, client_name: String) -> void:
	if not multiplayer.is_server():
		return

	var sender_id := multiplayer.get_remote_sender_id()

	print("SERVER: Client ", sender_id, " is ready for world ", world_id)

	var world = game_manager.get_world(world_id)

	if world == null:
		print("SERVER: World doesn't exist!")
		return

	if not world.level_loaded:
		world.load_level(world_id)
		world.level_loaded = true

	game_manager.spawn_plr(
		world_id,
		sender_id,
		client_name
	)



@rpc("any_peer", "reliable")
func join_game(file_name: String, client_name):
	if not multiplayer.is_server():
		return

	var player_id = multiplayer.get_remote_sender_id()

	print("Player ", player_id, " wants to join ", file_name)

	var world = game_manager.get_world(file_name)

	if world == null:
		world = game_manager.create_world(file_name)

	create_client_world.rpc_id(player_id, file_name, client_name)



func _on_map_button_selected(file_name: String) -> void:
	print("Player wants to join game file: ", file_name)

	join_game.rpc_id(1, file_name, plrUsr)

	loadMenu.visible = false
	layer.visible = false
	setWindowTitle("Playing a game")

	


@rpc("any_peer", "reliable")
func request_games_serv() -> void:
	if not multiplayer.is_server():
		return

	var sender_id := multiplayer.get_remote_sender_id()

	var games := get_games_serv()

	var game_list: Array = []

	for game in games:
		game_list.append({
			"name": game.get("name", "Unknown"),
			"creator": game.get("creator", "Unknown Bub"),
			"file_name": game.get("file_name", "")
		})

	print("sending list of games:")
	print(game_list)
	print("to peer: ", sender_id)

	recieve_games_server.rpc_id(sender_id, game_list)


func ask_serv_for_games() -> void:

	request_games_serv.rpc_id(1)

	print("Game request RPC sent")


func get_games_serv() -> Array:
	var packed_games_data: Array = []
	
	var exe_dir : String = OS.get_executable_path().get_base_dir()
	var path : String = exe_dir.path_join("BUBBOL-MAPS/")
	
	if DirAccess.dir_exists_absolute(path):
		var files = DirAccess.get_files_at(path)
		
		for file_name in files:
			if file_name.ends_with(".json"):
				var file_path = path.path_join(file_name)
				var file = FileAccess.open(file_path, FileAccess.READ)
				
				if file:
					var json_text = file.get_as_text()
					var map_data = JSON.parse_string(json_text)
					
					if map_data and map_data.has("name") and map_data.has("creator"):
						map_data["file_name"] = file_name 
						packed_games_data.append(map_data)
	else:
		print("Maps does not exist at: ", path)

	return packed_games_data
