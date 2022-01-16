extends Control

onready var button_list = $Buttons

# Called when the node enters the scene tree for the first time.
func _ready():
  for button in button_list.get_children():
    button.connect("pressed", self, "_on_Button_pressed", [button.function, button.scene_to_load])

func _on_Button_pressed(function, scene_to_load):
  if(function == "new"):
    new_game(scene_to_load)
  elif(function == "load"):
    load_game(scene_to_load)
  elif(function == "exit"):
      get_tree().quit()

func new_game(scene_to_load):
  MainGameLoop.is_new = true
  get_tree().change_scene(scene_to_load)

func load_game(scene_to_load):
  MainGameLoop.is_new = false
  var save_game = File.new()
  if not save_game.file_exists("user://savegame.save"):
    return # Error! We don't have a save to load.

  # We need to revert the game state so we're not cloning objects
  # during loading. This will vary wildly depending on the needs of a
  # project, so take care with this step.
  # For our example, we will accomplish this by deleting saveable objects.
  var save_nodes = get_tree().get_nodes_in_group("Persist")
  for i in save_nodes:
    i.queue_free()

  # Load the file line by line and process that dictionary to restore
  # the object it represents.
  save_game.open("user://savegame.save", File.READ)
  while save_game.get_position() < save_game.get_len():
    # Get the saved dictionary from the next line in the save file
    var node_data = parse_json(save_game.get_line())

    # Firstly, we need to create the object and add it to the tree and set its position.
    var new_object = load(node_data["filename"]).instance()
    get_node(node_data["parent"]).add_child(new_object)
    new_object.position = Vector2(node_data["pos_x"], node_data["pos_y"])

    # Now we set the remaining variables.
    for i in node_data.keys():
      if i == "filename" or i == "parent":
        continue
      new_object.set(i, node_data[i])

  save_game.close()
