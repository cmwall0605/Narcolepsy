extends StaticBody

var highlighted = false

onready var shader = $MeshInstance.mesh.surface_get_material(0).next_pass


func _highlight(val):
	highlighted = val
	if highlighted:
		# activate interact_shader
		shader.set_shader_param("border_width", 0.02)
	else:
		# deactivate interact_shader
		shader.set_shader_param("border_width", 0.0)

func _use():
	save_game()

func save_game():
	var save_game = File.new()
	save_game.open("user://savegame.save", File.WRITE)
	var save_nodes = get_tree().get_nodes_in_group("Persist")
	for node in save_nodes:
		if node.filename.empty():
			print("persistent node '%s' is not an instanced scene, skipped" % node.name)
			continue

		if !node.has_method("save"):
				print("persistent node '%s' is missing a save() function, skipped" % node.name)
				continue

		var node_data = node.call("save")

		save_game.store_line(to_json(node_data))
	save_game.close()

