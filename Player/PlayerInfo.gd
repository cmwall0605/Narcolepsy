extends Node

###############
## CONSTANTS ##
###############
export var BASE_HP : int = 100
var save_dict
const SAVE_KEY = "player"
###############
## VARIABLES ##
###############
var current_hp : float = BASE_HP
# Inventory is a dictionary with a string key and an item val. Items
# consist of a name, description, possibly a spatial equivalent, and a count
var inventory = {"weapon_inv" : {}, "ammo_inv": {}, "active_inv": {}, 
  "passive_inv": {}, "quest_inv": {} }

var is_playing = false

#######################
#  PLAYER FUNCTIONS   #
#######################
func reset():
  current_hp = BASE_HP
  inventory = {"weapon_inv" : {}, "ammo_inv": {}, "active_inv": {}, 
    "passive_inv": {}, "quest_inv": {} }

func get_is_playing():
  return is_playing

func set_is_playing(value):
  is_playing = value

#######################
# INVENTORY FUNCTIONS #
#######################

# APPEND FUNCTIONS
# Add item to appropriate inventory; return true if successful and false 
# otherwise.
func add_weapon(weapon, count = 1, is_load = false):
  if (inventory["weapon_inv"].has(weapon.id) and !is_load):
    print(inventory["weapon_inv"][weapon.id])
    inventory["weapon_inv"][weapon.id].add_count(count)
    return false
  var item = Item.new(weapon, count)
  inventory["weapon_inv"][weapon.id] = item
  return true

func add_ammo(ammo, count = 1, is_load = false):
  if (inventory["ammo_inv"].has(ammo.id) and !is_load):
    inventory["ammo_inv"][ammo.id].add_count(count)
    return false
  var item = Item.new(ammo, count)
  inventory["ammo_inv"][ammo.id] = item
  return true

func add_active(active, count = 1, is_load = false):
  if (inventory["active_inv"].has(active.id) and !is_load):
    inventory["active_inv"][active.id].add_count(count)
    return false
  var item = Item.new(active, count)
  inventory["active_inv"][active.id] = item
  return true

func add_passive(passive, count = 1, is_load = false):
  if (inventory["passive_inv"].has(passive.id) and !is_load):
    inventory["passive_inv"][passive.id].add_count(count)
    return false
  var item = Item.new(passive, count)
  inventory["passive_inv"][passive.id] = item
  return true

func add_quest(quest, count = 1, is_load = false):
  if (inventory["quest_inv"].has(quest.id) and !is_load):
    inventory["quest_inv"][quest.id].add_count(count)
    return false
  var item = Item.new(quest, count)
  inventory["quest_inv"][quest.id] = item
  return true


# REMOVAL FUNCTIONS
# Remove item from its inventory; return true if successful and false otherwise.
func remove_weapon(id, count):
  if (inventory["weapon_inv"].has(id)):
    var item = inventory["weapon_inv"][id]
    var newCount  = item.count - count
    if(newCount > 0):
      item.sub_count(count)
    else:
      inventory["weapon_inv"].erase(id)
  return false

func remove_ammo(id, count):
  if (inventory["ammo_inv"].has(id)):
    var item = inventory["ammo_inv"][id]
    var newCount  = item.count - count
    if(newCount > 0):
      item.sub_count(count)
    else:
      inventory["ammo_inv"].erase(id)
  return false

func remove_active(id, count):
  if (inventory["active_inv"].has(id)):
    var item = inventory["active_inv"][id]
    var newCount  = item.count - count
    if(newCount > 0):
      item.sub_count(count)
    else:
      inventory["active_inv"].erase(id)
  return false

func remove_passive(id, count):
  if (inventory["passive_inv"].has(id)):
    var item = inventory["passive_inv"][id]
    var newCount  = item.count - count
    if(newCount > 0):
      item.sub_count(count)
    else:
      inventory["passive_inv"].erase(id)
  return false

func remove_quest(id, count):
  if (inventory["quest_inv"].has(id)):
    var item = inventory["quest_inv"][id]
    var newCount  = item.count - count
    if(newCount > 0):
      item.sub_count(count)
    else:
      inventory["quest_inv"].erase(id)
  return false

# GET FUNCTIONS 
# get the item from the inventory it should be via its name. Return the item
# if it is in the inventory and null otherwise.

func get_weapon(id):
  if (inventory["weapon_inv"].has(id)):
    return inventory["weapon_inv"][id]
  return null

func get_ammo(id):
  if (inventory["ammo_inv"].has(id)):
    return inventory["ammo_inv"][id]
  return null

func get_active(id):
  if (inventory["active_inv"].has(id)):
    return inventory["active_inv"][id]
  return null

func get_passive(id):
  if (inventory["passive_inv"].has(id)):
    return inventory["passive_inv"][id]
  return null
  
func get_quest(id):
  if (inventory["quest_inv"].has(id)):
    return inventory["quest_inv"][id]
  return null
# Save player info, which includes inventory
func save(save_game):
  var saved_weapon_inv = {}
  var saved_ammo_inv = {}
  var saved_active_inv = {}
  var saved_passive_inv = {}
  var saved_quest_inv = {}
  for key in inventory["weapon_inv"]:
    saved_weapon_inv[inventory["weapon_inv"][key].item_id] = inventory["weapon_inv"][key].count
  for key in inventory["ammo_inv"]:
    saved_ammo_inv[inventory["ammo_inv"][key].item_id] = inventory["ammo_inv"][key].count
  for key in inventory["active_inv"]:
    saved_active_inv[inventory["active_inv"][key].item_id] = inventory["active_inv"][key].count
  for key in inventory["passive_inv"]:
    saved_passive_inv[inventory["passive_inv"][key].item_id] = inventory["passive_inv"][key].count
  for key in inventory["quest_inv"]:
    saved_quest_inv[inventory["quest_inv"][key].item_id] = inventory["quest_inv"][key].count
  save_dict = {
    "current_health" : current_hp,
    "weapon_inv" : saved_weapon_inv, 
    "ammo_inv": saved_ammo_inv, 
    "active_inv": saved_active_inv, 
    "passive_inv": saved_passive_inv, 
    "quest_inv": saved_quest_inv
  }
  save_game.data[SAVE_KEY] = save_dict
  
func load(save_game):
  current_hp = save_game.data[SAVE_KEY]["current_health"]
  for key in save_game.data[SAVE_KEY]["weapon_inv"]:
    PlayerInfo.add_weapon(MainGameLoop.get_item(key), save_game.data[SAVE_KEY]["weapon_inv"][key], true)
  for key in save_game.data[SAVE_KEY]["ammo_inv"]:
    PlayerInfo.add_ammo(MainGameLoop.get_item(key), save_game.data[SAVE_KEY]["ammo_inv"][key], true)
  for key in save_game.data[SAVE_KEY]["active_inv"]:
    PlayerInfo.add_active(MainGameLoop.get_item(key), save_game.data[SAVE_KEY]["active_inv"][key], true)
  for key in save_game.data[SAVE_KEY]["passive_inv"]:
    PlayerInfo.add_passive(MainGameLoop.get_item(key), save_game.data[SAVE_KEY]["passive_inv"][key], true)
  for key in save_game.data[SAVE_KEY]["quest_inv"]:
    PlayerInfo.add_quest(MainGameLoop.get_item(key), save_game.data[SAVE_KEY]["quest_inv"][key], true)
  #inventory = save_game.data[SAVE_KEY]["inventory"]
