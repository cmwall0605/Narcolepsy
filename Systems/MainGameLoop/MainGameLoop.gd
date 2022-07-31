extends Node

var players : Array
var actors : Array
var is_new : bool = true
var item_list = {}
const SaveGame = preload("res://Systems/Save/SaveGame.gd")

const SAVE_DIR = "user://saves/"
const SAVE_FILE = "save_%03d.tres"

func instantiate_player(player : Spatial, parent : Spatial, spawn_location : Vector3):
  players.append(player)
  parent.add_child(player)
  player.global_transform.origin = spawn_location
  return player

func instantiate_actor(actor : Spatial, parent : Spatial, spawn_location : Vector3):
  actors.append(actor)
  parent.add_child(actor)
  actor.global_transform.origin = spawn_location
  return actor

func _ready():
  var file = File.new()
  file.open("res://Objects/item_list.json", file.READ)
  var text = file.get_as_text()
  item_list = JSON.parse(text).get_result()
  file.close()

func get_player(i):
  return players[i]

func new_game():
  is_new = true
  PlayerInfo.reset();

func get_item(id : String) :
  if(item_list.has(id)):
    return item_list[id]
  return null

func get_item_name(id : String) :
  if(item_list[id] != null):
    return item_list[id]["name"]
  return null

func get_item_desc(id : String) :
  if(item_list[id] != null):
    return item_list[id]["desc"]
  return null

func save(id: int = 1):
  var save_game = SaveGame.new()
  save_game.game_version = ProjectSettings.get_setting("application/config/version")
  for node in get_tree().get_nodes_in_group("save"):
    node.save(save_game)
  var directory = Directory.new()
  if !directory.dir_exists(SAVE_DIR):
    directory.make_dir_recursive(SAVE_DIR)
  
  var save_path = SAVE_DIR.plus_file(SAVE_FILE % id)
  var error = ResourceSaver.save(save_path, save_game)
  if error != OK:
    print("Error in saving!")

func load(id: int = 1):
  is_new = false
  var save_file_path = SAVE_DIR.plus_file(SAVE_FILE % id)
  var file = File.new()
  if !file.file_exists(save_file_path):
    print("Save does not exist!")
    return
  var save_game = load(save_file_path)
  for node in get_tree().get_nodes_in_group('save'):
    node.load(save_game)
