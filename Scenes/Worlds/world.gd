extends Spatial

# Get items which should already be in the world
onready var ambience_audio = $Ambience
onready var player_spawn = $PlayerSpawnLocation
onready var marionette_spawn = $MarionetteSpawnLocation

# Get items 
onready var player_scene = preload("res://Player/Player.tscn")
onready var gui_scene = preload("res://GUI/GameUI/PlayerGUI.tscn")
onready var marionette_scene = preload("res://NPCs/Enemies/marionette/Marionette.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
  # Instanstiate the player into the scene
  MainGameLoop.players = Array()
  MainGameLoop.instantiate_player(player_scene.instance(), self, player_spawn.global_transform.origin)

  # Instantiate the gui into the scene
  add_child(gui_scene.instance())

  # Instantiate the marionette into the scene
  MainGameLoop.actors = Array()
  MainGameLoop.instantiate_actor(marionette_scene.instance(), self, marionette_spawn.global_transform.origin)

  # Play Ambience
  ambience_audio.play()
  
  PlayerInfo.set_is_playing(true)


