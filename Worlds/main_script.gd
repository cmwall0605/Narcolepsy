extends Spatial

onready var ambience_audio = get_node("Ambience")

# Called when the node enters the scene tree for the first time.
func _ready():
	ambience_audio.play()


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
