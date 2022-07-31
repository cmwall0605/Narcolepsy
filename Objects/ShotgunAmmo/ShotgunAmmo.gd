extends StaticBody

#General
export var ID : String = "100"
export var COUNT : int = 10
var highlighted        = false

onready var shader = $MeshInstance.mesh.surface_get_material(0).next_pass


func _highlight(val):
  highlighted = val
  if highlighted:
    # activate interact_shader
    shader.set_shader_param("border_width", 0.2)
  else:
    # deactivate interact_shader
    shader.set_shader_param("border_width", 0.0)

func _use():
  pickup()

func pickup():
  PlayerInfo.add_ammo(MainGameLoop.get_item(ID), COUNT)
  hide()
  queue_free()
