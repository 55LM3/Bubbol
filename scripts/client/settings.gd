extends Control



@onready var detectTxt = $container/detect

func string_contains(text: String, arr: Array) -> bool:
	for word in arr:
		if text.containsn(word):
			return true
	return false



var badlist = [
	"Nigger",
	"Retard",
	"Faggot",
	"Cunt",
	"F.a.g.g.o.t",
	"Fa gg ot",
	"f a g g o t",
	"TheHaloDeveloper",
	"r e t a r d",
	"n i g g e r",
	"nigga",
	"n i g g a"
]




func _on_exit_pressed() -> void:
	visible = not visible




func _on_custom_usr_text_changed(new_text: String) -> void:
	if string_contains(new_text, badlist):
		detectTxt.visible = true
		Global.curr_name = "[REDACTED]"
	else:
		Global.curr_name = new_text
		detectTxt.visible = false
