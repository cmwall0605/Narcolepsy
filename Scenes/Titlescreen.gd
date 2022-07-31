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
    MainGameLoop.load()
    var error = get_tree().change_scene(scene_to_load)
    if error != OK:
      print("New game scene change failure!")
  elif(function == "exit"):
      get_tree().quit()

func new_game(scene_to_load):
  MainGameLoop.new_game()
  var error = get_tree().change_scene(scene_to_load)
  if error != OK:
    print("New game scene change failure!")
