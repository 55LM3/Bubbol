extends Node

var worlds: Dictionary = {}


func create_world(id: String):
	if worlds.has(id):
		return worlds[id]

	var world = preload("res://scenes/server/world.tscn").instantiate()

	world.name = "map_" + id

	add_child(world)

	worlds[id] = world

	print("Created world: ", id)

	return world


func get_world(id: String):
	return worlds.get(id)


func spawn_plr(worldID, sender_id, clientName):
	var world = get_world(worldID)
	
	if world == null:
		print("Null world ID: " + worldID)
		return
	
	world.spawn_plr(sender_id, clientName)



func create_client_world(id: String):
	if worlds.has(id):
		return worlds[id]

	var world = preload("res://scenes/server/world.tscn").instantiate()

	world.name = "map_" + id

	add_child(world)

	worlds[id] = world

	print("Client created world: ", id)

	return world
