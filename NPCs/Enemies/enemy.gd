extends KinematicBody

export var MAX_HEALTH = 50

var health
var is_alive

onready var collision = get_node("CollisionShape")
onready var mesh = get_node("MeshInstance")

# Called when the node enters the scene tree for the first time.
func _ready():
	health = MAX_HEALTH
	is_alive = true

func _process(delta):
	if health == 0 && is_alive:
		handle_death()


func bullet_hit(damage, ray_transform):
	health = clamp(health - damage, 0, MAX_HEALTH)
		
func handle_death():
	rotate(Vector3 (0, 0, 1), 90)
	is_alive = false