# Shotgun script for the shotgun scene

extends Spatial

###############
## CONSTANTS ##
###############

#General
var ID : String  = "1"
var ANIM_POS = 2
export var MAGAZINE : float = 7
export var DAMAGE : float   = 20
var AMMO_ID : String      = "101"

# Shooting
export var SHOOT_TIME : float    = 0.4
export var PELLET_COUNT : float  = 1
export var HIT_SCAN_LENGTH : int = 200
export var ROTATION_DEGREE : int = 0
export var RECOIL : float = -2.5
export var DROP_OFF = 0.1

# Reload
export var RELOAD_TIME_START : float = 0.417
export var RELOAD_TIME_MID : float   = 0
export var RELOAD_TIME_END_E : float = 1.25	
export var RELOAD_TIME_END_F : float = 0.833
export var RELOAD_AMOUNT : int = 7

export var DEFAULT_TRANSFORM = Transform(Vector3(-0.717, 0.089, 0.2), Vector3(0.217, 0.202, 0.689), Vector3(0.028, 0.717, -0.218), Vector3(0.006, 0.027, 0.007))

# Scenes
var PELLET_SCENE = preload("res://Weapons/PelletRaycast.tscn")

###############
## VARIABLES ##
###############

var pellet_ray_array  = []
var current_mag_count = MAGAZINE
var chambered         = true
var countdown         = 2

signal anim_step_complete
signal gun_noise

#Elements
onready var pistol_anim_player    = $AnimationPlayer
onready var pistol_point          = $PistolPoint
onready var pistol_fire_audio     = $AudioManager/PistolFire
onready var pistol_dry_fire_audio = $AudioManager/PistolDryFire
onready var muzzle_flash           = $MuzzleFlash
onready var anim_timer             = $ReloadTimer
onready var shader_cache           = $ShaderCache
onready var crosshair              = $PistolPoint/Crosshair

# Called before the first frame of the game; sets up the muzzle and crosshair
#   visibility. Additionally, initialize the pistol pellet.
func _ready():
  muzzle_flash.visible = false
  crosshair.visible = false
  for _i in range (0, PELLET_COUNT):
    var ray = PELLET_SCENE.instance()
    pistol_point.add_child(ray)
    pellet_ray_array.append(ray)
    
func _process(_delta):
  manage_shader_cache()

func set_crosshair(val):
  crosshair.visible = val


func manage_shader_cache():
  if countdown > 0:
    countdown -= 1
    if countdown == 0:
      shader_cache.visible = false

func get_weapon_id():
  return ID

func get_ammo_id():
  return AMMO_ID

func can_shoot():
  if(chambered):
    return anim_timer.is_stopped()
  elif !pistol_dry_fire_audio.playing:
    pistol_dry_fire_audio.play()
  return false

func can_reload():
  return current_mag_count < MAGAZINE

func is_chambered():
  return chambered

# Shoot the shotgun
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
      if body.owner.is_in_group("enemy_collision"):
        var distance = ray.global_transform.origin.distance_to(ray.get_collision_point())
        if body.owner.has_method("_bullet_hit"):
          body.owner._bullet_hit(calc_dmg(distance), ray.get_collider().name, null)
  muzzle_flash.get_node("AnimationPlayer").play("Fire")
  pistol_anim_player.play("pistol_shoot")
  emit_signal("gun_noise")
  if(current_mag_count > 0):
    current_mag_count = current_mag_count - 1
  else:
    chambered = false

func calc_dmg(dist):
  var numerator = DAMAGE
  var denominator = (DROP_OFF * dist) + 1
  return numerator/denominator

func reload_gun_start():
  anim_timer.set_wait_time(RELOAD_TIME_START)
  anim_timer.start()
  
func reload_gun_mid(_remaining_ammo):
  var amount_used = min(_remaining_ammo, RELOAD_AMOUNT - current_mag_count)
  anim_timer.set_wait_time(RELOAD_TIME_MID)
  anim_timer.start()
  current_mag_count += amount_used
  return amount_used

func reload_gun_end():
  if(chambered):
    anim_timer.set_wait_time(RELOAD_TIME_END_F)
  else:
    anim_timer.set_wait_time(RELOAD_TIME_END_E)
    current_mag_count -= 1
    chambered = true
    pistol_anim_player.play("pistol_reload_e")
  anim_timer.start()
    
func _on_anim_timeout():
  anim_timer.stop()
  emit_signal("anim_step_complete")
