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


#im so fucking tired
#game dev and software engineering isnt as fun as it was before
#its so fucking tiring
#i dont even want to own this game anymore
#but my greedy fucking brain wants me to stay as owner with all power
#omfg
#im just so fucking tired
#tired of life
#tired of my boring day
#tired of everything
#omfg
#i dont like to code anymore
#its not fun
#its just a fucking pain in the ass
#god
#i fucking hate this
#this fucking shit
#jeez am i just yapping to myself?
#im just so fucking tired of software engineering
#i dont like it anymore
#im tired of life im tired of coding
#i try to hide it
#but its just so fucking tiring
#every fucking day
#i dont wanna own this game
#i dont wanna code
#im just bored
#bored of life
