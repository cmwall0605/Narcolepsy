extends Control

onready var button_list = $Buttons

# Called when the node enters the scene tree for the first time.
func _ready():
	for button in button_list.get_children():
		button.connect("pressed", self, "_on_Button_pressed", [button.scene_to_load])

func _on_Button_pressed(scene_to_load):
	if(scene_to_load == "Exit"):
		get_tree().quit()
	else:
		get_tree().change_scene(scene_to_load)
