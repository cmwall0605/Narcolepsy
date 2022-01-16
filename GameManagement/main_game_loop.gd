extends Node

var players : Array
var actors : Array
var is_new : bool = true
var item_list = {}

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
  print(item_list)
  file.close()

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
