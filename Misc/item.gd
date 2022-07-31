class_name Item

var item_id : String
var item_name : String
var item_desc : String
var scene : String
var spatial : Spatial
var count : int

func _init(item, _count : int = 1):
  print(item)
  item_id = item.id
  item_name = item.name
  item_desc = item.desc
  scene = item.scene
  if(scene != "NULL"):
    spatial = load(scene).instance()
  count = _count
  
func intialize_item():
  if scene == "NULL":
    return null
  
func add_count(amount):
  count += amount
  
func sub_count(amount):
  count -= amount
