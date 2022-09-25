extends Node

var queue = []
var cache = {}

var paths_calc_per_turn = 1

func _physics_process(_delta):
  for _i in range(paths_calc_per_turn):
    deqeue_path_request()

func deqeue_path_request():
  if(queue.size() == 0):
    return
  var calc_path_info = queue.pop_front()
  var agent: Spatial = calc_path_info.agent
  if !is_instance_valid(agent):
    return
  var nav: Navigation = calc_path_info.nav
  var start_pos = agent.global_transform.origin
  var end_pos = agent.get_target_move_pos()
  var new_path = nav.get_simple_path(start_pos, end_pos)
  cache.erase(str(agent))
  agent.update_path(new_path)


func calc_path(agent: Spatial, nav: Navigation):
  var key = str(agent)
  if key in cache:
    return
  cache[key] = ""
  queue.append({"agent": agent, "nav": nav})
   
