extends Node

var players : Array
var actors : Array

func instantiate_player(player : Spatial, spawn_location : Vector3):
	players.append(player)
	player.global_transform.origin = spawn_location
	return player

func instantiate_actor(actor : Spatial, spawn_location : Vector3):
	actors.append(actor)
	actor.global_transform.origin = spawn_location
	return actor
