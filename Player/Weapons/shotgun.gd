extends Spatial

#General
export var MAGAZINE : float = 5
export var DAMAGE : float = 5
var AMMO_TYPE : String = "12g"
# Pellets
export var PELLET_COUNT : float = 9
export var HIT_SCAN_LENGTH : int = 80
export var ROTATION_DEGREE : int = 7
# Reload
export var RELOAD_TIME_START : float = 0.8333
export var RELOAD_TIME_MID : float = 0.4167
export var RELOAD_TIME_END_E : float = 1.25	
export var RELOAD_TIME_END_F : float = 0.833

var shoot_time
var player_node
var pellet_ray_array = []
var current_mag_count = MAGAZINE
var chambered = true

onready var shotgun_anim_player = get_node("AnimationPlayer")
onready var shotgun_point = get_node("ShotgunPoint")
onready var shotgun_fire_audio = get_node("ShotgunFire")
onready var shotgun_dry_fire_audio = get_node("ShotgunDryFire")
onready var muzzle_flash = get_node("MuzzleFlash")
onready var reload_timer = get_node("ReloadTimer")

signal reload_step_complete

func _ready():
	shoot_time = shotgun_anim_player.get_animation("Shoot").length
	for i in range (0, PELLET_COUNT):
		var name = "PelletRayCast%d" % i
		var rotation = Vector3()
		rotation = Vector3.ZERO
		pellet_ray_array.append(shotgun_point.get_node(name))

func get_ammo_type():
	return AMMO_TYPE

func can_shoot():
	if(chambered):
		return true
	elif !shotgun_dry_fire_audio.playing:
		shotgun_dry_fire_audio.play()
	return false

func can_reload():
	return current_mag_count < MAGAZINE

func is_chambered():
	return chambered

func shoot_gun():
	for i in range (0, PELLET_COUNT):
		var ray = pellet_ray_array[i]
		ray.cast_to.x = rand_range(ROTATION_DEGREE, -ROTATION_DEGREE)
		ray.cast_to.z = rand_range(ROTATION_DEGREE, -ROTATION_DEGREE)
		ray.force_raycast_update()
		if ray.is_colliding():
			var body = ray.get_collider()
			if body.is_in_group("enemy"):
				body.bullet_hit(DAMAGE, ray.global_transform)
	muzzle_flash.get_node("AnimationPlayer").play("Fire")
	shotgun_anim_player.play("Shoot")
	if(current_mag_count > 0):
		current_mag_count = current_mag_count - 1
	else:
		chambered = false

func reload_gun_start():
	reload_timer.set_wait_time(RELOAD_TIME_START)
	reload_timer.start()
	
func reload_gun_mid(remaining_ammo):
	reload_timer.set_wait_time(RELOAD_TIME_MID)
	reload_timer.start()
	current_mag_count += 1
	return 1

func reload_gun_end():
	if(chambered):
		reload_timer.set_wait_time(RELOAD_TIME_END_F)
	else:
		reload_timer.set_wait_time(RELOAD_TIME_END_E)
		current_mag_count -= 1
		chambered = true
		shotgun_anim_player.play("Shotgun Reload")
	reload_timer.start()
		
func _on_reloadtimer_timeout():
	reload_timer.stop()
	emit_signal("reload_step_complete")
