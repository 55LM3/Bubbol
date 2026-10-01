#its hell to make an entire programming language !!!!!

extends Node

@onready var output_container = $Control/panel/vbox
@onready var output_template = $Control/panel/vbox/OUTPUT
@onready var ctrlNode = $Control

var vars = {}





var mouse_buttons = {
	"left": MOUSE_BUTTON_LEFT,
	"right": MOUSE_BUTTON_RIGHT,
	"middle": MOUSE_BUTTON_MIDDLE,
}



func tokenize(line: String) -> Array:
	return line.strip_edges().split(" ", false)


func run_script(userscript: String, attachment):
	var lines = userscript.split("\n")
	var i = 0
	
	while i < lines.size():
		var line = lines[i].strip_edges()
		
		if "#" in line:
			line = line.split("#")[0].strip_edges()
		
		var tokens = tokenize(line)
		
		if tokens.is_empty():
			i += 1
			continue
			
		var command = tokens[0]
		
		if command == "repeat":
			if tokens.size() < 2:
				i += 1
				continue
				
			var counter = tokens[1].to_int()
			
			var start_index = i + 1
			var end_index = find_matching_end(lines, start_index)
			
			var block_lines = lines.slice(start_index, end_index)
			var block_script = "\n".join(block_lines)
			
			for r in range(counter):
				await run_script(block_script, attachment)
				
			i = end_index + 1
			continue
			
		if command == "forever":
			
			var start_index = i + 1
			var end_index = find_matching_end(lines, start_index)
			
			var block_lines = lines.slice(start_index, end_index)
			var block_script = "\n".join(block_lines)
			
			while true:
				await run_script(block_script, attachment)
				await get_tree().process_frame
				
			i = end_index + 1
			continue
			
			
		if command == "on_key_down":
			if tokens.size() < 2:
				i += 1
				continue
				
			var keytopress = tokens[1]
			var key = OS.find_keycode_from_string(keytopress)
			
			var start_index = i + 1
			var end_index = find_matching_end(lines, start_index)
			
			var block_lines = lines.slice(start_index, end_index)
			var block_script = "\n".join(block_lines)
			
			if Input.is_key_pressed(key):
				await run_script(block_script, attachment)
				
			i = end_index + 1
			continue
			
			
		if command == "on_mouse_down":
			if tokens.size() < 2:
				i += 1
				continue

			var button = mouse_buttons.get(tokens[1].to_lower(), -1)

			var start_index = i + 1
			var end_index = find_matching_end(lines, start_index)

			var block_lines = lines.slice(start_index, end_index)
			var block_script = "\n".join(block_lines)

			if button != -1 and Input.is_mouse_button_pressed(button):
				await run_script(block_script, attachment)

			i = end_index + 1
			continue
			
			if command == "if":
				if tokens.size() < 2:
					i += 1
					continue
				
			var condition_string = " ".join(tokens.slice(1))
			var condition_passed = parse_expr(condition_string)
			
			start_index = i + 1
			var block_boundaries = find_if_bounds(lines, start_index)
			var else_index = block_boundaries["else"]
			end_index = block_boundaries["end"]
			
			var true_lines = []
			var false_lines = []
			
			if else_index != -1:
				true_lines = lines.slice(start_index, else_index)
				false_lines = lines.slice(else_index + 1, end_index)
			else:
				true_lines = lines.slice(start_index, end_index)
				
			if condition_passed:
				var true_script = "\n".join(true_lines)
				await run_script(true_script, attachment)
			elif else_index != -1:
				var false_script = "\n".join(false_lines)
				await run_script(false_script, attachment)
				
			i = end_index + 1
			continue

			
		await run_line(line, attachment)
		i += 1


func find_matching_end(lines: Array, start_from: int) -> int:
	var depth = 1
	for idx in range(start_from, lines.size()):
		var tokens = tokenize(lines[idx])
		if tokens.is_empty():
			continue
			
		if tokens[0] == "repeat"  or tokens[0] == "on_key_down" or tokens[0] == "if" or tokens[0] == "forever" or tokens[0] == "on_mouse_down":
			depth += 1
		elif tokens[0] == "end":
			depth -= 1
			if depth == 0:
				return idx #end of whatever ur doing boiii. what the fuck was i saying? it was 2 AM i was really tired.
				
	return lines.size()
	
	
	
	
	
	
func find_if_bounds(lines: Array, start_from: int) -> Dictionary:
	var result = {"else": -1, "end": lines.size()}
	var depth = 1
	
	for idx in range(start_from, lines.size()):
		var tokens = tokenize(lines[idx])
		if tokens.is_empty():
			continue
			
		if tokens[0] == "if" or tokens[0] == "repeat" or tokens[0] == "on_key_down" or tokens[0] == "forever" or tokens[0] == "on_mouse_down":
			depth += 1
		elif tokens[0] == "else" and depth == 1:
			result["else"] = idx
		elif tokens[0] == "end":
			depth -= 1
			if depth == 0:
				result["end"] = idx
				return result
				
	return result

	
	
	
func parse_expr(text: String):
	if vars.has(text):
		return convert_string_to_type(vars[text])
		
	var evaluation_context = {}
	for var_name in vars:
		evaluation_context[var_name] = convert_string_to_type(vars[var_name])

	var expr = Expression.new()
	
	var variable_names = evaluation_context.keys()
	var error = expr.parse(text, variable_names)
	
	if error != OK:
		return text
		
	var variable_values = evaluation_context.values()
	var result = expr.execute(variable_values, null, false)
	
	if expr.has_execute_failed():
		return text
		
	return result







var constructor_regex = RegEx.create_from_string("^[A-Z][A-Za-z0-9]*\\(.*\\)$")

func convert_string_to_type(val_string: String):
	if val_string.is_valid_int():
		return val_string.to_int()
	if val_string.is_valid_float():
		return val_string.to_float()
	if constructor_regex.search(val_string):
		var parsed = str_to_var(val_string)
		if parsed != null:
			return parsed
	return val_string





func eval_args(tokens: Array, attachment) -> Dictionary:
	if tokens.is_empty():
		return {"value": null, "consumed_tokens": 0}
		
	var current_node = attachment
	var i = 0
	
	while i < tokens.size():
		var token = tokens[i]
		
		if token == "getChild":
			if i + 1 >= tokens.size(): break
			var child_name = tokens[i + 1]
			if current_node:
				current_node = current_node.get_node_or_null(child_name)
			i += 2
			
		elif token == "getParent":
			if current_node:
				current_node = current_node.get_parent()
			i += 1
			
		elif token == "getval":
			if i + 1 >= tokens.size(): break
			var property_name = tokens[i + 1]
			var val = null
			if current_node and property_name in current_node:
				val = current_node.get(property_name)
			return {"value": val, "consumed_tokens": i + 2}
			
		elif token == "clone":
			if current_node:
				var new_node = current_node.duplicate()
				attachment.add_child(new_node)
				#current_node = new_node
			i += 1
			
		else:
			var raw_val = token
			if vars.has(raw_val):
				raw_val = vars[raw_val]
			return {"value": parse_expr(str(raw_val)), "consumed_tokens": i + 1}
			
	return {"value": current_node, "consumed_tokens": i}





func eval_segment(seg: Array, attachment):
	if seg.is_empty():
		return ""
	var eval = eval_args(seg, attachment)
	if eval["consumed_tokens"] < seg.size():
		return " ".join(seg)
	return eval["value"]


func eval_rest(args: Array, attachment):
	if args.is_empty():
		return ""
	var segments = [[]]
	for t in args:
		if t == "+":
			segments.append([])
		else:
			segments[-1].append(t)
	
	var result = eval_segment(segments[0], attachment)
	for n in range(1, segments.size()):
		result = combine(result, eval_segment(segments[n], attachment))
	return result


func combine(a, b):
	var a_num = typeof(a) == TYPE_INT or typeof(a) == TYPE_FLOAT
	var b_num = typeof(b) == TYPE_INT or typeof(b) == TYPE_FLOAT
	if a_num and b_num:
		return a + b
	if typeof(a) == typeof(b) and typeof(a) != TYPE_STRING and typeof(a) != TYPE_OBJECT:
		return a + b
	return str(a) + str(b)



func run_line(userscript: String, attachment):
	var tokens = tokenize(userscript)
	if tokens.is_empty():
		return

	var command = tokens[0]

	match command:
		"print":
			if tokens.size() < 2: return
			var output = " ".join(tokens.slice(1))
			if vars.has(output): output = vars[output]
			var eval = eval_args(tokens.slice(1), attachment)
			add_output(str(eval_rest(tokens.slice(1), attachment)), attachment)

		"var":
			if tokens.size() < 2: return
			var var_tokens = tokens.slice(2)
			var val = eval_rest(tokens.slice(2), attachment)
			vars[tokens[1]] = val if typeof(val) == TYPE_STRING else var_to_str(val)

		"add":
			if tokens.size() < 2: return
			var varname = tokens[1]
			var newnum = tokens[2].to_int()
			if vars.has(varname):
				vars[varname] = str(vars[varname].to_int() + newnum)

		"sub":
			if tokens.size() < 2: return
			var varname = tokens[1]
			var newnum = tokens[2].to_int() 
			if vars.has(varname):
				vars[varname] = str(vars[varname].to_int() - newnum)
				
		"wait":
			if tokens.size() < 2: return
			var waittime = tokens[1]
			await get_tree().create_timer(waittime.to_float()).timeout
		"setval":
			if tokens.size() < 3:
				return
				
			var property = tokens[1]
			var expression = " ".join(tokens.slice(2))
			
			var property_val = parse_expr(expression)
			
			if attachment and property in attachment:
				attachment.set(property, property_val)
			else:
				print("Property not found: " + property) #what? why am i being so indescriptive! nope not that indescriptive anymore!
				add_error("Property not found: " + property, attachment)
				
		"getChild":
			if tokens.size() < 3: 
				return
				
			var child_name = tokens[1]
			
			var child_node = null
			if attachment:
				child_node = attachment.get_node_or_null(child_name)
				
			if child_node == null:
				print("not found child named: " + child_name)
				add_error("not found child named: " + child_name, attachment)
				return
				
			var remainng_cmd = " ".join(tokens.slice(2))
			
			await run_line(remainng_cmd, child_node)
			
		"getParent":
			if tokens.size() < 2: 
				return
				
			
			var parent_node = null
			if attachment:
				parent_node = attachment.get_parent()
				
			if parent_node == null:
				print("Parent of script attachment is null")
				add_error("Parent of script attachment is null", attachment)
				return
				
			var remainng_cmd = " ".join(tokens.slice(1))
			
			await run_line(remainng_cmd, parent_node)
			
		"clone":
			if attachment == null:
				return
			var new_node = attachment.duplicate()
			var parent = attachment.get_parent()
			if parent:
				parent.add_child(new_node)
				new_node.add_to_group("_CLONE")
				new_node.name = attachment.name + "_CLONE" 

				
			
			

		_:
			print("Unknown cmd: ", command)
			add_error("Unknown cmd: " + command, attachment)


func add_output(text, att):
	var new_label = output_template.duplicate()
	new_label.text = "[" + att.name + "]: " + text
	output_container.add_child(new_label)
	
	
	
	
	
	
func add_error(text, att):
	var new_label : Label = output_template.duplicate()
	new_label.text = "[" + att.name + "]: " + text
	new_label.add_theme_color_override("font_color", Color.RED)
	output_container.add_child(new_label)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_opt"):
		ctrlNode.visible = not ctrlNode.visible
