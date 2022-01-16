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
func add_weapon(weapon, count = 1):
  if (inventory["weapon_inv"].has(weapon.id)):
    inventory["weapon_inv"][weapon.id].add_count(count)
    return false
  var item = Item.new(weapon, count)
  inventory["weapon_inv"][weapon.id] = item
  return true

func add_ammo(ammo, count = 1):
  if (inventory["ammo_inv"].has(ammo.id)):
    inventory["ammo_inv"][ammo.id].add_count(count)
    return false
  var item = Item.new(ammo, count)
  inventory["ammo_inv"][ammo.id] = item
  return true

func add_active(active, count = 1):
  if (inventory["active_inv"].has(active.id)):
    inventory["active_inv"][active.id].add_count(count)
    return false
  var item = Item.new(active, count)
  inventory["active_inv"][active.id] = item
  return true

func add_passive(passive, count = 1):
  if (inventory["passive_inv"].has(passive.id)):
    inventory["passive_inv"][passive.id].add_count(count)
    return false
  var item = Item.new(passive, count)
  inventory["passive_inv"][passive.id] = item
  return true

func add_quest(quest, count = 1):
  if (inventory["quest_inv"].has(quest.id)):
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

func save():
  var save_dict = {
    "filename" : get_filename(),
    "parent" : get_parent().get_path(),
    "current_health" : current_hp,
    "inventory" : inventory
  }
  return save_dict
