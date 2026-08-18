extends Node
class_name SyncHandler

var multSynchronizer := MultiplayerSynchronizer.new()

func _ready() -> void:
	add_child(multSynchronizer)
	multSynchronizer.replication_config = SceneReplicationConfig.new()
	multSynchronizer.root_path = multSynchronizer.get_path_to(get_tree().root)


func SetSyncConstant(node: Node, property: NodePath) -> void:
	setSync(node, property, true)


func SetSyncOnChange(node: Node, property: NodePath) -> void:
	setSync(node, property, false)


func isValidProperty(node: Node, property: String) -> bool:
	var script: Script = node.get_script()
	for propDict: Dictionary in script.get_property_list():
		if propDict.name == property:
			
			if propDict.type == TYPE_OBJECT:
				push_error("Object type properties are not supported!")
				breakpoint
				return false
				
			return true
	return false


func getPropertyPath(node: Node, property: NodePath) -> NodePath:
	return NodePath("%s:%s" % [node.get_path(), property])


func setSync(node: Node, property: NodePath, constant: bool) -> void:
	if not isValidProperty(node, property):
		return
	
	var config: SceneReplicationConfig = multSynchronizer.replication_config
	
	var path: NodePath = getPropertyPath(node, property)
	config.add_property(path)
	
	#var index: int = config.property_get_index(path)
	
	if constant:
		config.property_set_replication_mode(
			path, SceneReplicationConfig.REPLICATION_MODE_ALWAYS
			)
	else:
		config.property_set_replication_mode(
			path, SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE
			)
	
	node.tree_exiting.connect(removeSync.bind(node, property))


func removeSync(node: Node, property: NodePath) -> void:
	var config: SceneReplicationConfig = multSynchronizer.replication_config
	var path: NodePath = getPropertyPath(node, property)
	config.remove_property(path)
