extends Control

@onready var chat_log: Label = $Chatbox/Scroller/VerticalBox/Message
@onready var chat_input: LineEdit = $Chatbox/MsgBox
@onready var send_button: Button = $Chatbox/Send

var username: String = "Username"

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
		return
	
	var full_message = "[" + username + "]: " + new_text
	
	send_chat_message.rpc(full_message)
	
	chat_input.clear()
	chat_input.release_focus()

@rpc("any_peer", "reliable", "call_local")
func send_chat_message(message: String) -> void:
	Global.is_typing = false
	
	chat_log.text += message + "\n"
	print(message)
