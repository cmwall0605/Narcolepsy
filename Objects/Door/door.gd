# Door class used in the interactable door object. Contains a highlight function, a
# use function and an oper door function.
extends StaticBody

var highlighted = false

onready var shader = $MeshInstance.mesh.surface_get_material(0).next_pass

# Called on a trigger, highlights the door
func _highlight(val):
  highlighted = val
  if highlighted:
    # activate interact_shader
    shader.set_shader_param("border_width", 0.02)
  else:
    # deactivate interact_shader
    shader.set_shader_param("border_width", 0.0)

# Called on a trigger, runs the open door function
func _use():
  open_door()

# Function to open the door. Currently  it simply prints to console.
func open_door():
  print("*woosh*")
