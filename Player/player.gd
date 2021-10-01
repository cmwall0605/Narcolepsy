extends KinematicBody
## CONSTANTS ##
# Movement
export var SPEED : float  = 350
var GRAVITY : float = ProjectSettings.get_setting("physics/3d/default_gravity")
export var MAX_TERMINAL_VELOCITY : float = 980
export var ROTATION_SPEED : float = 25

# Walk animation
export var WALK_PROGRESSION_RATE : float = 0.1
export var AIM_PROGRESSION_RATE : float = 0.1

# Camera
export var CAMERA_FOV : float = 50.0
export var CAMERA_ARM_Z_BASE_LENGTH : float = 4
export var CAMERA_ZOOM : float = 1
export var CAMERA_ZOOM_RATE : float = 0.1

# Mouse Input
export(float, 0.1, 1) var MOUSE_SENSITIVITY : float = 0.3
export(float, -90, 0) var MIN_PITCH : float = -60
export(float, 0, 90) var MAX_PITCH : float = 60

# Finite State Machine Points
enum State {IDLE, SPRINT, RELOAD_START, RELOAD_MID, RELOAD_END, AIM, USE, SHOOT, DEAD}
enum AnimationState {IDLE, AIM, RELOAD}
enum ReloadAnimationState {START, MID, END_E, END_F}

# Game Stats
export var HP : int = 100

## NODES ##
# Camera
onready var cam_rot_h = $CamRotationH
onready var cam_rot_v = $CamRotationH/CamRotationV
onready var camera = $CamRotationH/CamRotationV/CameraBoomX/CameraBoomZ/CameraOffset/Camera
onready var camera_arm_z = $CamRotationH/CamRotationV/CameraBoomX/CameraBoomZ
onready var front = $CamRotationH/Front
# Playermodel
onready var player_model = $Playermodel
onready var ik_spine = $Playermodel/Skeleton/SpineIK
onready var ik_spine_target = $IKTargetNormalizer
# Animations
onready var player_anim_tree = $AnimationTree
# Audio
onready var audio_manager = $AudioManager
onready var slow_footstep_audio = $AudioManager/SlowFootStepAudio
onready var med_footstep_audio = $AudioManager/MedFootStepAudio
var current_gun : Spatial = null

## VARIABLES ##
# Movement
var movement_velocity : Vector3 = Vector3.ZERO
var snap_vector : Vector3 = Vector3.ZERO
var current_speed
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
# Ammo (0 = shotgun)
var ammo_dict = {"12g": 15}

func _ready():
	current_speed = SPEED
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera.fov = CAMERA_FOV
	set_equipment($Playermodel/Skeleton/WeaponHolder/Shotgun)
	
func _process(delta):
	handle_state()
	handle_zoom(delta)
	handle_anim()
	handle_audio()

func _physics_process(delta):
	handle_movement(delta)

func _input(event):
	if event is InputEventMouseMotion:

		cam_rot_v.rotation_degrees.x -= event.relative.y * MOUSE_SENSITIVITY
		cam_rot_v.rotation_degrees.x = clamp(cam_rot_v.rotation_degrees.x, MIN_PITCH, MAX_PITCH)
		if aim_mode:
			player_model.rotation_degrees.y -= event.relative.x * MOUSE_SENSITIVITY
		cam_rot_h.rotation_degrees.y -= event.relative.x * MOUSE_SENSITIVITY
		ik_spine_target.rotation_degrees.y -= event.relative.x * MOUSE_SENSITIVITY
		ik_spine_target.rotation_degrees.x += event.relative.y * MOUSE_SENSITIVITY
		ik_spine_target.rotation_degrees.x = clamp(ik_spine_target.rotation_degrees.x, MIN_PITCH, MAX_PITCH)

func set_equipment(item : Spatial):
	current_gun = item
	current_weapon_blend_tree = "%s_tree" % current_gun.get_name()
	reload_anim_fsm = player_anim_tree.get("parameters/%s/reload_fsm/playback" % current_weapon_blend_tree)

func handle_state():
	# State Check
	match current_state:
		State.IDLE:
			# IDLE -> DEAD (TODO)
			# IDLE -> SPRINT (TODO)
			# IDLE -> AIM
			if Input.is_action_pressed("aim_gun"):
				current_state = State.AIM
				player_anim_tree.set("parameters/%s/ub_transition/current" % current_weapon_blend_tree, AnimationState.AIM)
				player_anim_tree.set("parameters/lb_transition/current", AnimationState.AIM)
				player_model.look_at(front.global_transform.origin, Vector3.UP)
				current_speed = SPEED/3
				aim_mode = true
				ik_spine.start()
			# IDLE -> RELOAD_START
			elif Input.is_action_just_pressed("reload") && current_gun.can_reload() && ammo_dict[current_gun.get_ammo_type()] != 0:
				current_state = State.RELOAD_START
				player_anim_tree.set("parameters/%s/ub_transition/current" % current_weapon_blend_tree, AnimationState.RELOAD)
				reload_anim_fsm.travel("start")
				current_gun.reload_gun_start()
			# IDLE -> USE (TODO)
			# IDLE -> IDLE
			else:
				current_state = State.IDLE

		State.SPRINT: #TODO
			# SPRINT -> IDLE (TODO)
			pass

		State.RELOAD_START: 
			# Check if the current animation is done
			if !anim_step_complete:
				current_state = State.RELOAD_START
			# RELOAD_START -> RELOAD_MID
			else:
				anim_step_complete = false
				current_state = State.RELOAD_MID
				reload_anim_fsm.travel("mid")
				ammo_dict[current_gun.get_ammo_type()] -= current_gun.reload_gun_mid(ammo_dict[current_gun.get_ammo_type()])

		State.RELOAD_MID:
			# Check if the current animation is done
			if !anim_step_complete:
				current_state = State.RELOAD_MID
			# RELOAD_MID -> RELOAD_END
			elif !current_gun.can_reload() || ammo_dict[current_gun.get_ammo_type()] == 0:
				anim_step_complete = false
				current_state = State.RELOAD_END
				if current_gun.is_chambered():
					reload_anim_fsm.travel("end_f")
				else:
					reload_anim_fsm.travel("end_e")
				current_gun.reload_gun_end()
			# RELOAD_MID -> RELOAD_MID
			else:
				anim_step_complete = false
				current_state = State.RELOAD_MID
				ammo_dict[current_gun.get_ammo_type()] -= current_gun.reload_gun_mid(ammo_dict[current_gun.get_ammo_type()])

		State.RELOAD_END:
			# Check if the current animation is done
			if !anim_step_complete:
				current_state = State.RELOAD_END
			# RELOAD_END -> IDLE
			else:
				anim_step_complete = false
				current_state = State.IDLE
				player_anim_tree.set("parameters/%s/ub_transition/current" % current_weapon_blend_tree, AnimationState.IDLE)

		State.AIM:
			
			# AIM -> DEAD (TODO)
			# AIM -> SHOOT
			if Input.is_action_just_pressed("shoot_gun") && current_gun.can_shoot():
				current_state = State.SHOOT
				handle_shooting()
			# AIM -> AIM
			elif Input.is_action_pressed("aim_gun"):
				current_state = State.AIM
			# AIM -> IDLE
			else:
				current_state = State.IDLE
				player_anim_tree.set("parameters/%s/ub_transition/current" % current_weapon_blend_tree, AnimationState.IDLE)
				player_anim_tree.set("parameters/lb_transition/current", AnimationState.IDLE)
				current_speed = SPEED
				aim_mode = false
				ik_spine.stop()

		State.USE: #TODO
			# USE -> DEAD (TODO)
			pass

		State.SHOOT:
			# SHOOT -> DEAD (TODO)
			# Check if animation is complete
			if !anim_step_complete:
				current_state = State.SHOOT
			# SHOOT -> SHOOT
			else:
				anim_step_complete = false
				current_state = State.AIM
			pass

		State.DEAD: #TODO
			# DEAD -> IDLE (TODO)
			# DEAD -> DEAD (TODO)
			pass

func handle_zoom(delta):
	camera_arm_z.spring_length += -CAMERA_ZOOM_RATE * delta if aim_mode else CAMERA_ZOOM_RATE * delta
	camera_arm_z.spring_length = clamp(camera_arm_z.spring_length, CAMERA_ARM_Z_BASE_LENGTH - CAMERA_ZOOM, CAMERA_ARM_Z_BASE_LENGTH)

func handle_shooting():
	current_gun.shoot_gun()
	# Shoot animation handler
	player_anim_tree.set("parameters/%s/shoot/active" % current_weapon_blend_tree, true)

func handle_movement(delta):
	var input_vector = get_input_vector()
	var gravity_vel = apply_gravity()
	apply_movement(input_vector, delta)
	print(movement_velocity + gravity_vel)
	movement_velocity = move_and_slide(movement_velocity + gravity_vel, Vector3.UP)


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

func apply_movement(input_vector, delta):
	# Rotate input vector globally for movement
	var global_rot_input_vector = input_vector.rotated(Vector3.UP, cam_rot_h.global_transform.basis.get_euler().y)
	if !aim_mode && input_vector.length() != 0:
		var local_rot_input_vector = input_vector.rotated(Vector3.UP, cam_rot_h.rotation.y)
		player_model.rotation.y = lerp_angle(player_model.rotation.y, atan2(local_rot_input_vector.x, local_rot_input_vector.z) + deg2rad(90), ROTATION_SPEED * delta)
	movement_velocity.x = global_rot_input_vector.x * current_speed
	movement_velocity.z = global_rot_input_vector.z * current_speed

func apply_gravity():
	var g_vel = Vector3()
	if is_on_floor():
		g_vel = -get_floor_normal() * GRAVITY
	else:
		g_vel.y = -GRAVITY
	print(g_vel)
	return g_vel

func handle_anim():
	# Walk animation handler
	player_anim_tree.set("parameters/lb_idle_blendspace/blend_position", walk_anim_vector)
	player_anim_tree.set("parameters/lb_aim_blendspace/blend_position", walk_anim_vector)
	player_anim_tree.set("parameters/upper_lower_blend/blend_amount", walk_progression)
	player_anim_tree.set("parameters/%s/walk_sway_blend/blend_amount" % current_weapon_blend_tree, walk_progression)

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
