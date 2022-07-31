# Script which handles the saving functionality of the game
extends Node

const SAVE_GAME = preload("res://Systems/Save/SaveGame.gd")

const SAVE_DIR = "user://saves/"
const SAVE_FILE = "save_%03d.tres"

func save(id: int):
  var save_game := SAVE_GAME.new()
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

func load(id:int):
  var save_file_path = SAVE_DIR.plus_file(SAVE_FILE % id)
  var file = File.new()
  if !file.file_exists(save_file_path):
    print("Save does not exist!")
    return
  
  var save_game = load(save_file_path)
  for node in get_tree().get_nodes_in_group('save'):
    node.load(save_game)
