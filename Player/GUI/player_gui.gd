extends CanvasLayer

onready var pause_menu = $PauseMenu

var title_screen = "res://Scenes/title_screen.tscn"

func _ready():
	pause_menu.visible = false
	for button in pause_menu.get_node("Menu/Buttons").get_children():
		button.connect("pressed", self, "_on_pause_button_pressed", [button.button_name])

func _set_pause_menu(set : bool):
	pause_menu.visible = set

func _on_pause_button_pressed(button_name):
	match(button_name):
		"load":
			pass
		"options":
			pass
		"exit":
			get_tree().paused = false
			get_tree().change_scene(title_screen)
