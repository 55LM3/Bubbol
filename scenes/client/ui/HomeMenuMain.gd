extends Control

var usrname = "Bub"

@onready var serv = get_parent()

@onready var hellousr = $helloUsr


func _ready():
	hellousr.text = "Hello, " + usrname + "!"
