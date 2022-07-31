extends Spatial

# Get items which should already be in the world
onready var player_spawn = $PlayerSpawnLocation
onready var marionette_spawn = $MarionetteSpawnLocation

# Get items 
onready var player_scene = preload("res://Player/playermodel_old.tscn")
onready var gui_scene = preload("res://GUI/GameUI/PlayerGUI.tscn")
onready var marionette_scene = preload("res://NPCs/Enemies/marionette/marionette.tscn")
var player
var gui
var marionette

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
