extends Control

@onready var chat_log: Label = $Vbox/Chatbox/Scroller/VerticalBox/Message
@onready var chat_input: LineEdit = $Vbox/MsgBox
@onready var send_button: Button = $Vbox/Send

var username: String = "Username"

const MAX_CHARS = 200



# i removed the slurs from the list because it will instead force quit your game LMAO!
var badWords = {
	"fuck": "duck",
	"shit": "shoot",
	"dick": "stick",
	"pussy": "kitty",
	"penis": "stick",
	"dih": "stick",
	"bitch": "beach",
	"cunt": "bruh",
	"bastard": "oops",
	"twat": "ah"
}



var veryBadWords = [
	"nigger",
	"nigga",
	"retard"
]

func _ready() -> void:
	chat_input.text_submitted.connect(_on_chat_input_text_submitted)
	send_button.pressed.connect(_on_send_button_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("chat"):
		chat_input.grab_focus()
		Global.is_typing = true

func _on_send_button_pressed() -> void:
	_on_chat_input_text_submitted(chat_input.text)

func _on_chat_input_text_submitted(new_text: String) -> void:
	if new_text.strip_edges() == "":
		chat_input.clear()
		chat_input.release_focus()
		Global.is_typing = false
		return
		
	username = Global.curr_name
	
	var full_message = "[" + username + "]: " + new_text
	
	send_chat_message.rpc(full_message)
	
	chat_input.clear()
	chat_input.release_focus()

@rpc("any_peer", "reliable", "call_local")
func send_chat_message(message: String) -> void:
	Global.is_typing = false
	
	var msgLength = message.length()
	
	var lowerMsg = message.to_lower()
	
	
	if msgLength <= MAX_CHARS:
		
		for slur in veryBadWords:
			if slur in lowerMsg:
				get_tree().quit()
				return
		
		for badWord in badWords:
				var replaced = badWords[badWord]
				message = message.replacen(badWord, replaced)
		
		chat_log.text += message + "\n"
		print(message)






func _on_msg_box_focus_entered() -> void:
	chat_input.grab_focus()
	Global.is_typing = true
	
	
func _process(delta: float) -> void:
	if Global.is_builder == true:
		visible = false
	else:
		visible = true
	
	
