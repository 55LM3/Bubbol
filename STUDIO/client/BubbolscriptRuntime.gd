extends Node

@onready var output_container = $Control/panel/vbox
@onready var output_template = $Control/panel/vbox/OUTPUT
@onready var ctrlNode = $Control

var currVar = "NOBUB"


func run_script(userscript):
	if userscript.begins_with("print "):
		var output = userscript.trim_prefix("print ")

		if output == "var":
			output = currVar

		add_output(output)
		return

	if userscript.begins_with("var "):
		var newvariable = userscript.trim_prefix("var ")
		currVar = newvariable
		return
	
	if userscript.begins_with("add "):
		
		var newn = userscript.trim_prefix("add ")
		
		var newnum = newn.to_int()
		var final = currVar.to_int() + newnum
		currVar = str(final)
		return
		
	if userscript.begins_with("sub "):
		
		var newn = userscript.trim_prefix("sub ")
		
		var newnum = newn.to_int()
		var final = currVar.to_int() - newnum
		currVar = str(final)
		return


func add_output(text):
	var new_label = output_template.duplicate()
	new_label.text = "[OUTPUT]: " + text
	
	output_container.add_child(new_label)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_opt"):
		ctrlNode.visible = not ctrlNode.visible
