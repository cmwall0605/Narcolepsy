extends Node

###############
## CONSTANTS ##
###############
export var BASE_HP : int = 100

###############
## VARIABLES ##
###############
var current_hp = BASE_HP
# Inventory is a dictionary with a string key and an item val. Items
# consist of a name, description, possibly a spatial equivalent, and a count
var inventory = {"weapon_inv" : {}, "ammo_inv": {}, "active_inv": {}, 
  "passive_inv": {}, "quest_inv": {} }

#######################
# INVENTORY FUNCTIONS #
#######################

# APPEND FUNCTIONS
# Add item to appropriate inventory; return true if successful and false 
# otherwise.
func add_weapon(weapon):
  if (inventory["weapon_inv"].has(weapon.item_name)):
    return false
  inventory["weapon_inv"][weapon.item_name] = weapon
  return true

func add_ammo(ammo):
  if (inventory["ammo_inv"].has(ammo.item_name)):
    return false
  inventory["ammo_inv"][ammo.item_name] = ammo
  return true

func add_active(active):
  if (inventory["active_inv"].has(active.item_name)):
    return false
  inventory["active_inv"][active.item_name] = active
  return true

func add_passive(passive):
  if (inventory["passive_inv"].has(passive.item_name)):
    return false
  inventory["passive_inv"][passive.item_name] = passive
  return true

func add_quest(quest):
  if (inventory["quest_inv"].has(quest.item_name)):
    return false
  inventory["quest_inv"][quest.item_name] = quest
  return true


# REMOVAL FUNCTIONS
# Remove item from its inventory; return true if successful and false otherwise.
func remove_weapon(weapon):
  if (inventory["weapon_inv"].has(weapon.item_name)):
    inventory["weapon_inv"].erase(weapon.item_name)
    return true
  return false

func remove_ammo(ammo):
  if (inventory["ammo_inv"].has(ammo.item_name)):
    inventory["ammo_inv"].erase(ammo.item_name)
    return true
  return false

func remove_active(active):
  if (inventory["active_inv"].has(active.item_name)):
    inventory["active_inv"].erase(active.item_name)
    return true
  return false

func remove_passive(passive):
  if (inventory["passive_inv"].has(passive.item_name)):
    inventory["passive_inv"].erase(passive.item_name)
    return true
  return false

func remove_quest(quest):
  if (inventory["quest_inv"].has(quest.item_name)):
    inventory["quest_inv"].erase(quest.item_name)
    return true
  return false

# GET FUNCTIONS 
# get the item from the inventory it should be via its name. Return the item
# if it is in the inventory and null otherwise.
func get_ammo(ammo_name):
  if (inventory["ammo_inv"].has(ammo_name)):
    return inventory["ammo_inv"][ammo_name]
  return null

func get_active(active_name):
  if (inventory["active_inv"].has(active_name)):
    return inventory["active_inv"][active_name]
  return null

func get_passive(passive_name):
  if (inventory["passive_inv"].has(passive_name)):
    return inventory["passive_inv"][passive_name]
  return null
  
func get_quest(quest_name):
  if (inventory["quest_inv"].has(quest_name)):
    return inventory["quest_inv"][quest_name]
  return null

func save():
  var save_dict = {
      "filename" : get_filename(),
      "parent" : get_parent().get_path(),
      "current_health" : current_hp,
      "inventory" : inventory
  }
  return save_dict
