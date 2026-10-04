extends Control

@onready var user = $Fields/Username
@onready var password = $Fields/Password

@onready var serv = get_parent()


func _ready():
	print(serv)
	print(serv.has_method("register"))


func _on_create_acc_pressed() -> void:
	print(multiplayer.multiplayer_peer)
	print(multiplayer.get_unique_id())
	
	serv.register.rpc_id(
		1,
		user.text,
		password.text
	)




func _on_log_in_pressed() -> void:
	serv.login.rpc_id(
		1,
		user.text,
		password.text
	)
