extends Node

func _ready() -> void:
	create_documents_folder("Bubbol Builder")

func create_documents_folder(folder_name: String) -> void:
	var docs_path: String = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	
	var target_path: String = docs_path.path_join(folder_name)
	
	if not DirAccess.dir_exists_absolute(target_path):
		var error = DirAccess.make_dir_absolute(target_path)
		
		if error == OK:
			print("successful creation at ", target_path)
		else:
			print("failed to make with error ", error)
	else:
		return
