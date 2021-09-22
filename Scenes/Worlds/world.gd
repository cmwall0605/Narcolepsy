extends Spatial

# Get items which should already be in the world
onready var ambience_audio = $Ambience
onready var player_spawn = $PlayerSpawnLocation
onready var marionette_spawn = $MarionetteSpawnLocation

# Get items 
onready var player_scene = preload("res://Player/player.tscn")
onready var gui_scene = preload("res://Player/GUI/player_gui.tscn")
onready var marionette_scene = preload("res://NPCs/Enemies/marionette.tscn")
var player
var gui
var marionette
var in_menu  = false

# Called when the node enters the scene tree for the first time.
func _ready():
	# Instanstiate the player into the scene
	player = player_scene.instance()
	add_child(player)
	player.global_transform.origin = player_spawn.global_transform.origin

	# Instantiate the gui into the scene
	gui = gui_scene.instance()
	add_child(gui)

	# Instantiate the marionette into the scene
	marionette = marionette_scene.instance()
	add_child(marionette)
	marionette.global_transform.origin = marionette_spawn.global_transform.origin

	# Play Ambience
	ambience_audio.play()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	handle_pause()

func handle_pause():
	if Input.is_action_just_pressed("ui_cancel"):
		if !in_menu:
			in_menu = true
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			get_tree().paused = true
			gui._set_pause_menu(true)
		else:
			in_menu = false
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			get_tree().paused = false
			gui._set_pause_menu(false)
