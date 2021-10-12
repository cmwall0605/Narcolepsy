extends Spatial
#Scenes
var pellet_scene = preload("res://Player/Weapons/pellet_raycast.tscn")
#General
export var NAME : String = "shotgun"
export var MAGAZINE : float = 5
export var DAMAGE : float = 5
var AMMO_TYPE : String = "12g"
# Shooting
export var SHOOT_TIME : float = 1.3
export var PELLET_COUNT : float = 10
export var HIT_SCAN_LENGTH : int = 80
export var ROTATION_DEGREE : int = 7
# Reload
export var RELOAD_TIME_START : float = 0.8333
export var RELOAD_TIME_MID : float = 0.4167
export var RELOAD_TIME_END_E : float = 1.25	
export var RELOAD_TIME_END_F : float = 0.833

var pellet_ray_array = []
var current_mag_count
var chambered = true
var countdown = 2

onready var shotgun_anim_player = $AnimationPlayer
onready var shotgun_point = $ShotgunPoint
onready var shotgun_fire_audio = $AudioManager/ShotgunFire
onready var shotgun_dry_fire_audio = $AudioManager/ShotgunDryFire
onready var muzzle_flash = $MuzzleFlash
onready var anim_timer = $ReloadTimer
onready var shader_cache = $ShaderCache

signal anim_step_complete

func _ready():
	muzzle_flash.visible = false
	current_mag_count = MAGAZINE
	for i in range (0, PELLET_COUNT):
		var ray = pellet_scene.instance()
		shotgun_point.add_child(ray)
		pellet_ray_array.append(ray)

func _process(delta):
	manage_shader_cache()

func manage_shader_cache():
	if countdown > 0:
		countdown -= 1
		if countdown == 0:
			shader_cache.visible = false

func get_name():
	return NAME

func get_ammo_type():
	return AMMO_TYPE

func can_shoot():
	if(chambered):
		return anim_timer.is_stopped()
	elif !shotgun_dry_fire_audio.playing:
		shotgun_dry_fire_audio.play()
	return false

func can_reload():
	return current_mag_count < MAGAZINE

func is_chambered():
	return chambered

func shoot_gun():
	anim_timer.set_wait_time(SHOOT_TIME)
	anim_timer.start()
	for i in range (0, PELLET_COUNT):
		var ray = pellet_ray_array[i]
		ray.cast_to.x = rand_range(ROTATION_DEGREE, -ROTATION_DEGREE)
		ray.cast_to.z = rand_range(ROTATION_DEGREE, -ROTATION_DEGREE)
		ray.force_raycast_update()
		if ray.is_colliding():
			var body = ray.get_collider()
			print("Body: ",ray.get_collider().name)
			print("Body Owner: ", body.owner.name)
			if body.owner.is_in_group("enemy_collision"):
				body.owner._bullet_hit(calc_dmg(ray.global_transform), ray.get_collider().name, null)
	muzzle_flash.get_node("AnimationPlayer").play("Fire")
	shotgun_anim_player.play("Shoot")
	if(current_mag_count > 0):
		current_mag_count = current_mag_count - 1
	else:
		chambered = false

func calc_dmg(dist):
	return 10 * (1/((1/4)*dist+1))

func reload_gun_start():
	anim_timer.set_wait_time(RELOAD_TIME_START)
	anim_timer.start()
	
func reload_gun_mid(remaining_ammo):
	anim_timer.set_wait_time(RELOAD_TIME_MID)
	anim_timer.start()
	current_mag_count += 1
	return 1

func reload_gun_end():
	if(chambered):
		anim_timer.set_wait_time(RELOAD_TIME_END_F)
	else:
		anim_timer.set_wait_time(RELOAD_TIME_END_E)
		current_mag_count -= 1
		chambered = true
		shotgun_anim_player.play("Shotgun Reload")
	anim_timer.start()
		
func _on_anim_timeout():
	anim_timer.stop()
	emit_signal("anim_step_complete")
