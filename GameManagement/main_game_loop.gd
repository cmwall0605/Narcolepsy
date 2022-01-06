extends Node

var players : Array
var actors : Array
var is_new : bool = true

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
