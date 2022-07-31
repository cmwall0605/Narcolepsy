extends KinematicBody

###############
## CONSTANTS ##
###############
# Movement
export var SPEED : float  = 5
var GRAVITY : float = ProjectSettings.get_setting("physics/3d/default_gravity")
export var MAX_TERMINAL_VELOCITY : float = 980
export var ROTATION_SPEED : float = 25
export var AIM_SPEED_REDUCTION : float = 0.3
# Walk animation
export var WALK_PROGRESSION_RATE : float = 0.1
export var AIM_PROGRESSION_RATE : float = 0.1
# Camera
export var CAMERA_FOV : float = 50.0
export var CAMERA_ARM_Z_BASE_LENGTH : float = 2.5
export var CAMERA_ZOOM : float = 1
export var CAMERA_ZOOM_RATE : float = 10
# Mouse Input
export(float, 0.1, 1) var MOUSE_SENSITIVITY : float = 0.3
export(float, -90, 0) var MIN_PITCH : float = -60
export(float, 0, 90) var MAX_PITCH : float = 60
# Finite State Machine Points
enum State {IDLE, SPRINT, RELOAD_START, RELOAD_MID, RELOAD_END, AIM, SHOOT, DEAD}
enum AnimationState {IDLE, AIM, RELOAD}
enum ReloadAnimationState {START, MID, END_E, END_F}
# Use
export var USE_TIME = 0.1


###########
## NODES ##
###########
# Camera
onready var cam_rot_h = $CamRotationH
onready var cam_rot_v = $CamRotationH/CamRotationV
onready var camera = $CamRotationH/CamRotationV/CameraBoomX/CameraBoomZ/CameraOffset/Camera
onready var camera_arm_z = $CamRotationH/CamRotationV/CameraBoomX/CameraBoomZ
onready var front = $CamRotationH/Front
# Playermodel
onready var player_model = $Armature
onready var ik_spine = $Armature/Skeleton/SpineIK
onready var ik_spine_target = $IKTargetNormalizer
# Animations
onready var player_anim_tree = $AnimationTree
# Audio
onready var audio_manager = $AudioManager
onready var slow_footstep_audio = $AudioManager/SlowFootStepAudio
onready var med_footstep_audio = $AudioManager/MedFootStepAudio
# Items
var current_item
onready var weapon_holder = $Armature/Skeleton/WeaponHolder
# Use
onready var use_raycast = $CamRotationH/CamRotationV/CameraBoomX/CameraBoomZ/CameraOffset/Camera/UseCast
onready var use_crosshair = $CamRotationH/CamRotationV/CameraBoomX/CameraBoomZ/CameraOffset/Camera/UseCrosshair
onready var use_highlight_timer = $HighlightTimer

###############
## VARIABLES ##
###############
# Movement
var movement_velocity : Vector3 = Vector3.ZERO
var snap_vector : Vector3 = Vector3.ZERO
var current_speed = SPEED
# Animation
var current_weapon_blend_tree
var reload_anim_fsm
var walk_progression: float = 0
var walk_anim_vector : Vector2 = Vector2.ZERO
# State Machine
var current_state = State.IDLE
var aim_mode = false
# Reload animation
var anim_step_complete = false
# Use
var highlighted_object : StaticBody = null

# Function ran at the first frame of the player's creation. Meant to set up
# variables that only exist after creation.
func _ready():
  Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
  use_crosshair.visible = false
  camera.fov = CAMERA_FOV
  if(MainGameLoop.is_new):
    PlayerInfo.add_weapon(MainGameLoop.get_item("0"), 1)
    PlayerInfo.add_weapon(MainGameLoop.get_item("1"), 1)
  var base_weapon = PlayerInfo.get_weapon("1")
  if base_weapon != null:
    set_equipment(PlayerInfo.get_weapon("1").spatial)
  else:
    set_equipment(null)

# Ran at every frame; Sets the state, zoom, animation, and audio.
func _process(delta):
  update_highlight()
  handle_state()
  handle_zoom(delta)
  handle_anim()
  handle_audio()

func update_highlight():
  if use_highlight_timer.is_stopped():
    use_highlight_timer.start(USE_TIME)
    if current_state == State.IDLE:
      use_raycast.force_raycast_update()
      var collision = use_raycast.get_collider()
      if collision != highlighted_object and (collision == null or collision.is_in_group("object")):
        if collision != null and collision.has_method("_highlight"):
          collision._highlight(true)
        if highlighted_object != null and is_instance_valid(highlighted_object):
          if highlighted_object.has_method("_highlight"):
            highlighted_object._highlight(false)
        highlighted_object = collision
    use_crosshair.visible = highlighted_object != null and current_state == State.IDLE


# Ran at every physics frame. Since it is meant to handle physics based things,
# it only handles the movement of the palyer
func _physics_process(delta):
  handle_movement(delta)

# Ran when an input is given by the player.
func _input(event):
  # Ran when the mouse is moved.
  if event is InputEventMouseMotion:
    handle_cam_movement(event.relative.y * MOUSE_SENSITIVITY, event.relative.x * MOUSE_SENSITIVITY)
  if event.is_action_pressed("use"):
    handle_use()
  if Input.is_key_pressed(KEY_1) && current_state == State.IDLE:
    set_equipment(PlayerInfo.get_weapon("0").spatial)
  if Input.is_key_pressed(KEY_2) && current_state == State.IDLE:
    set_equipment(PlayerInfo.get_weapon("1").spatial)
  if Input.is_key_pressed(KEY_3) && current_state == State.IDLE:
    set_equipment(null)

func handle_cam_movement(vertical, horizontal):
    # Handle vertical and horizontal rotation of the camera
    cam_rot_v.rotation_degrees.x -= vertical
    cam_rot_v.rotation_degrees.x = clamp(cam_rot_v.rotation_degrees.x, MIN_PITCH, MAX_PITCH)
    cam_rot_h.rotation_degrees.y -= horizontal

    # Handle playermodel movement
    if aim_mode:
      player_model.rotation_degrees.y -= horizontal
    ik_spine_target.rotation_degrees.y -= horizontal
    ik_spine_target.rotation_degrees.x += vertical
    ik_spine_target.rotation_degrees.x = clamp(ik_spine_target.rotation_degrees.x, MIN_PITCH, MAX_PITCH)

func handle_use():
  if current_state != State.IDLE || highlighted_object == null:
    return
  if highlighted_object.has_method("_use"):
    highlighted_object._use()
  

# Sets the equipment of the player
func set_equipment(item : Spatial):
  if(current_item != null and current_item.get_parent() != null):
    current_item.get_parent().remove_child(current_item)
    current_item.disconnect("anim_step_complete", self, "_anim_animation_step")
  if item == null:
    current_item = null
    current_weapon_blend_tree = "empty_tree"
    player_anim_tree.set("parameters/current_weapon/current", 0)
    return
  current_item = item
  current_item.transform = current_item.DEFAULT_TRANSFORM
  weapon_holder.add_child(current_item)
  current_item.connect("anim_step_complete", self, "_anim_animation_step")
  current_weapon_blend_tree = "%s_tree" % current_item.get_weapon_id()
  reload_anim_fsm = player_anim_tree.get("parameters/%s/reload_fsm/playback" % current_weapon_blend_tree)
  player_anim_tree.set("parameters/current_weapon/current", current_item.ANIM_POS)

func handle_state():
  # State Check
  #ANY -> DEAD
  if current_state != State.DEAD && PlayerInfo.current_hp <= 0:
    handle_death()
    current_state = State.DEAD
  match current_state:
    State.IDLE:
      # IDLE -> SPRINT (TODO)
      # IDLE -> AIM
      if Input.is_action_pressed("aim_gun"):
        handle_aim()
      # IDLE -> RELOAD_START
      elif Input.is_action_just_pressed("reload") and can_reload():
        handle_reload()

    State.SPRINT: #TODO
      # SPRINT -> IDLE (TODO)
      pass

    State.RELOAD_START: 
      # RELOAD_START -> RELOAD_MID
      if anim_step_complete:
        handle_reload()

    State.RELOAD_MID:
      # RELOAD_MID -> RELOAD_END
      if anim_step_complete and (!current_item.can_reload() or PlayerInfo.get_ammo(current_item.get_ammo_id()) == null):
        handle_reload()
      # RELOAD_MID -> RELOAD_MID
      elif anim_step_complete:
        anim_step_complete = false
        var ammo_item = PlayerInfo.get_ammo(current_item.get_ammo_id())
        PlayerInfo.remove_ammo(current_item.get_ammo_id(), current_item.reload_gun_mid(ammo_item.count))

    State.RELOAD_END:
      # RELOAD_END -> IDLE
      if anim_step_complete:
        anim_step_complete = false
        current_state = State.IDLE
        player_anim_tree.set("parameters/%s/ub_transition/current" % current_weapon_blend_tree, AnimationState.IDLE)

    State.AIM:
      # AIM -> SHOOT
      if Input.is_action_just_pressed("shoot_gun") && current_item.can_shoot():
        handle_shooting()
      # AIM -> IDLE
      elif !Input.is_action_pressed("aim_gun"):
        handle_aim()

    State.SHOOT:
      # SHOOT -> AIM
      handle_shooting()


func can_reload():
  return current_item.can_reload() && PlayerInfo.get_ammo(current_item.get_ammo_id()) != null
    

func handle_reload():
    match current_state:
      State.IDLE:
        current_state = State.RELOAD_START
        player_anim_tree.set("parameters/%s/ub_transition/current" % current_weapon_blend_tree, AnimationState.RELOAD)
        reload_anim_fsm.travel("start")
        current_item.reload_gun_start()
      State.RELOAD_START:
        # Check if the current animation is done
        current_state = State.RELOAD_MID
        anim_step_complete = false
        reload_anim_fsm.travel("mid")
        var ammo_item = PlayerInfo.get_ammo(current_item.get_ammo_id())
        ammo_item.sub_count(current_item.reload_gun_mid(ammo_item.count))
      State.RELOAD_MID:
        current_state = State.RELOAD_END
        anim_step_complete = false
        if current_item.is_chambered():
          reload_anim_fsm.travel("end_f")
        else:
          reload_anim_fsm.travel("end_e")
        current_item.reload_gun_end()

func handle_aim():
  if current_item == null:
    return
  if(current_state == State.IDLE):
    current_state = State.AIM
    player_anim_tree.set("parameters/%s/ub_transition/current" % current_weapon_blend_tree, AnimationState.AIM)
    player_anim_tree.set("parameters/lb_transition/current", AnimationState.AIM)
    player_model.look_at(front.global_transform.origin, Vector3.UP)
    current_speed = SPEED * AIM_SPEED_REDUCTION
    aim_mode = true
    if current_item.has_method("set_crosshair"):
      current_item.set_crosshair(true)
    ik_spine.start()
  else:
    current_state = State.IDLE
    player_anim_tree.set("parameters/%s/ub_transition/current" % current_weapon_blend_tree, AnimationState.IDLE)
    player_anim_tree.set("parameters/lb_transition/current", AnimationState.IDLE)
    current_speed = SPEED
    if current_item.has_method("set_crosshair"):
      current_item.set_crosshair(false)
    aim_mode = false
    ik_spine.stop()

func handle_death():
  aim_mode = false
  ik_spine.stop()

# Handle zoom (aim) of the player
func handle_zoom(delta):
  camera_arm_z.spring_length += -CAMERA_ZOOM_RATE * delta if aim_mode else CAMERA_ZOOM_RATE * delta
  camera_arm_z.spring_length = clamp(camera_arm_z.spring_length, CAMERA_ARM_Z_BASE_LENGTH - CAMERA_ZOOM, CAMERA_ARM_Z_BASE_LENGTH)
  

# Handle the shooting coming from the player
func handle_shooting():
  if(current_state == State.AIM):
    current_state = State.SHOOT
    current_item.shoot_gun()
    
    # Apply recoil
    handle_cam_movement(current_item.RECOIL, 0)
    
    # Shoot animation handler
    player_anim_tree.set("parameters/%s/shoot/active" % current_weapon_blend_tree, true)
  else:
    if anim_step_complete:
      anim_step_complete = false
      current_state = State.AIM


# Handle the movement of the player
func handle_movement(delta):
  if current_state == State.DEAD:
    return
  var input_vector = get_input_vector()
  var gravity_vel = apply_gravity()
  apply_movement(input_vector, delta)
  movement_velocity = move_and_slide(movement_velocity + gravity_vel, Vector3.UP)

# Get the movement input from the player
func get_input_vector():
  # Input vector obtained from keyboard movement
  var input_vector = Vector3(
    Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
    0,
    Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
  )

  # Animation related values
  walk_progression += (WALK_PROGRESSION_RATE if input_vector.length() != 0 else -WALK_PROGRESSION_RATE)
  walk_progression = clamp(walk_progression, 0, 1)
  if aim_mode:
    walk_anim_vector = walk_anim_vector.linear_interpolate(Vector2(input_vector.x, input_vector.z), WALK_PROGRESSION_RATE)
  else:
    walk_anim_vector = walk_anim_vector.linear_interpolate(Vector2(0, -1), WALK_PROGRESSION_RATE)

  # Normalize the input vector so that vector length is always 1
  return input_vector.normalized()

# Apply movement to the player
func apply_movement(input_vector, delta):
  # Rotate input vector globally for movement
  var global_rot_input_vector = input_vector.rotated(Vector3.UP, cam_rot_h.global_transform.basis.get_euler().y)
  if !aim_mode && input_vector.length() != 0:
    var local_rot_input_vector = input_vector.rotated(Vector3.UP, cam_rot_h.rotation.y)
    player_model.rotation.y = lerp_angle(player_model.rotation.y, atan2(local_rot_input_vector.x, local_rot_input_vector.z) + deg2rad(90), ROTATION_SPEED * delta)
  movement_velocity.x = global_rot_input_vector.x * current_speed
  movement_velocity.z = global_rot_input_vector.z * current_speed

# Apply gravity to the player
func apply_gravity():
  var g_vel = Vector3()
  if is_on_floor():
    g_vel = -get_floor_normal() * GRAVITY
  else:
    g_vel.y = -GRAVITY
  return g_vel

# Handle the animation of the player
func handle_anim():
  # Walk animation handler
  player_anim_tree.set("parameters/lb_idle_blendspace/blend_position", walk_anim_vector)
  player_anim_tree.set("parameters/lb_aim_blendspace/blend_position", walk_anim_vector)
  player_anim_tree.set("parameters/upper_lower_blend/blend_amount", walk_progression)
  player_anim_tree.set("parameters/%s/walk_sway_blend/blend_amount" % current_weapon_blend_tree, walk_progression)
  
# Handle the audio coming from the player
func handle_audio():
  # Footsteps
  if walk_progression > 0.5 && is_on_floor():
    if aim_mode:
      if !slow_footstep_audio.playing:
        slow_footstep_audio.play()
    else:
      if !med_footstep_audio.playing:
        med_footstep_audio.play()
    return
  slow_footstep_audio.stop()
  med_footstep_audio.stop()

func _anim_animation_step():
  anim_step_complete = true

func _take_damage(_damage, _type):
  print("Player Hit!")
  PlayerInfo.current_hp -= _damage
