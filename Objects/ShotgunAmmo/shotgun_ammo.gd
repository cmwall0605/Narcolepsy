extends StaticBody

var highlighted = false

onready var shader = $MeshInstance.mesh.surface_get_material(0).next_pass


func _highlight(val):
	highlighted = val
	if highlighted:
		# activate interact_shader
		print("ammo on")
		shader.set_shader_param("border_width", 0.2)
	else:
		# deactivate interact_shader
		print("ammo off")
		shader.set_shader_param("border_width", 0.0)

func _use():
	open_door()

func open_door():
	print("*woosh*")
