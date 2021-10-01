extends CanvasLayer

onready var pause_menu = $PauseMenu

var title_screen = "res://Scenes/title_screen.tscn"
var in_menu  = false

func _ready():
	pause_menu.visible = false
	for button in pause_menu.get_node("Menu/Buttons").get_children():
		button.connect("pressed", self, "_on_pause_button_pressed", [button.button_name])

func _process(delta):
	handle_pause()

func set_pause_menu(set : bool):
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

func handle_pause():
	if Input.is_action_just_pressed("ui_cancel"):
		if !in_menu:
			in_menu = true
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			get_tree().paused = true
			set_pause_menu(true)
		else:
			in_menu = false
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			get_tree().paused = false
			set_pause_menu(false)
			
