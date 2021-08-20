extends KinematicBody
## CONSTANTS ##
# Movement
export var SPEED : float  = 5
export var GRAVITY : float = 0.98
export var MAX_TERMINAL_VELOCITY : float = 54
# Walk animation
export var WALK_PROGRESSION_RATE : float = 0.1
export var AIM_PROGRESSION_RATE : float = 0.1
# Camera
export var CAMERA_FOV : float = 50.0
export var CAMERA_ZOOM : float = 10.0
export var CAMERA_ZOOM_RATE : float = 1.0
# Mouse Input
export(float, 0.1, 1) var MOUSE_SENSITIVITY : float = 0.3
export(float, -90, 0) var MIN_PITCH : float = -60
export(float, 0, 90) var MAX_PITCH : float = 60
# FSM
enum State {IDLE, SPRINT, RELOAD_START, RELOAD_MID, RELOAD_END, AIM, USE, SHOOT, DEAD}
enum AnimationState {IDLE, AIM, RELOAD}
enum ReloadAnimationState {START, MID, END_E, END_F}
## NODES ##
onready var camera_pivot = $CameraPivot
onready var camera = $CameraPivot/CameraBoomZero/BoomOneOffset/CameraBoomOne/CameraOffset/Camera
onready var player_model = 	get_node("Playermodel")
onready var ik_spine = player_model.get_node("Skeleton").get_node("SpineIK")
onready var ik_spine_target = get_node("IKTargetNormalizer")
onready var player_anim_tree = get_node("AnimationTree")
onready var reload_anim_fsm = player_anim_tree.get("parameters/reload_fsm/playback")
onready var audio_manager = get_node("AudioManager")
onready var slow_footstep_audio = audio_manager.get_node("SlowFootStepAudio")
onready var med_footstep_audio = audio_manager.get_node("MedFootStepAudio")
var current_gun : Spatial = null

## VARIABLES ##
# Movement
var velocity : Vector3
var walk_anim_vector : Vector2 = Vector2.ZERO
var y_velocity : float
var direction : Vector3
# Walk animation
var walk_progression: float = 0
var is_getting_move_input : bool = false
var is_rotating : bool = false
var in_menu : bool = false
var current_state = State.IDLE
# Reload animation
var reload_step_complete = false
# Ammo (0 = shotgun)
var ammo_dict = {"12g": 5}

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera.fov = CAMERA_FOV
	current_gun = player_model.get_node("Skeleton").get_node("WeaponHolder").get_node("Shotgun")
	
func _process(delta):
	handle_menu()
	handle_state()
	handle_zoom()
	handle_anim()
	handle_audio()

func handle_menu():
	# Universal menu input check
	if Input.is_action_just_pressed("ui_cancel"):
		if !in_menu:
			in_menu = true
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			in_menu = false
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func handle_state():
	# State Check
	match current_state:
		State.IDLE:
			# IDLE -> DEAD (TODO)
			# IDLE -> SPRINT (TODO)
			# IDLE -> AIM
			if Input.is_action_pressed("aim_gun"):
				current_state = State.AIM
				player_anim_tree.set("parameters/ub_transition/current", AnimationState.AIM)
				player_anim_tree.set("parameters/lb_transition/current", AnimationState.AIM)
				ik_spine.start()
			# IDLE -> RELOAD_START
			elif Input.is_action_just_pressed("reload") && current_gun.can_reload() && ammo_dict[current_gun.get_ammo_type()] != 0:
				current_state = State.RELOAD_START
				player_anim_tree.set("parameters/ub_transition/current", AnimationState.RELOAD)
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
			# RELOAD_START -> RELOAD_START
			if !reload_step_complete:
				current_state = State.RELOAD_START
			# RELOAD_START -> RELOAD_MID
			else:
				reload_step_complete = false
				current_state = State.RELOAD_MID
				reload_anim_fsm.travel("mid")
				ammo_dict[current_gun.get_ammo_type()] -= current_gun.reload_gun_mid(ammo_dict[current_gun.get_ammo_type()])

		State.RELOAD_MID:
			# RELOAD_MID -> RELOAD_MID (current reload not finished)
			if !reload_step_complete:
				current_state = State.RELOAD_MID
			# RELOAD_MID -> RELOAD_END
			elif !current_gun.can_reload() || ammo_dict[current_gun.get_ammo_type()] == 0:
				reload_step_complete = false
				current_state = State.RELOAD_END
				if current_gun.is_chambered():
					reload_anim_fsm.travel("end_f")
				else:
					reload_anim_fsm.travel("end_e")
				current_gun.reload_gun_end()
			# RELOAD_MID -> RELOAD_MID
			else:
				reload_step_complete = false
				current_state = State.RELOAD_MID
				ammo_dict[current_gun.get_ammo_type()] -= current_gun.reload_gun_mid(ammo_dict[current_gun.get_ammo_type()])

		State.RELOAD_END:
			# RELOAD_END -> RELOAD_END
			if !reload_step_complete:
				current_state = State.RELOAD_END
			# RELOAD_END -> IDLE
			else:
				reload_step_complete = false
				current_state = State.IDLE
				player_anim_tree.set("parameters/ub_transition/current", AnimationState.IDLE)

		State.AIM:
			# AIM -> DEAD (TODO)
			# AIM -> SHOOT
			if Input.is_action_just_pressed("shoot_gun") && current_gun.can_shoot():
				current_state = State.SHOOT
				handle_shooting()
			# AIM -> SPRINT (TODO)
			# AIM -> RELOAD_START (TODO)
			# AIM -> AIM
			elif Input.is_action_pressed("aim_gun"):
				current_state = State.AIM
			# AIM -> IDLE
			else:
				current_state = State.IDLE
				player_anim_tree.set("parameters/ub_transition/current", AnimationState.IDLE)
				player_anim_tree.set("parameters/lb_transition/current", AnimationState.IDLE)
				ik_spine.stop()

		State.USE: #TODO
			# USE -> DEAD (TODO)
			pass

		State.SHOOT:
			# SHOOT -> DEAD (TODO)
			# SHOOT -> AIM
			if !player_anim_tree.get("parameters/shoot/active"):
				current_state = State.AIM
			# SHOOT -> SHOOT
			else:
				current_state = State.SHOOT
			pass

		State.DEAD: #TODO
			# DEAD -> IDLE (TODO)
			# DEAD -> DEAD (TODO)
			pass

func handle_zoom():
	camera.fov += -CAMERA_ZOOM_RATE if (current_state == State.AIM || current_state == State.SHOOT) else CAMERA_ZOOM_RATE
	camera.fov = clamp(camera.fov, CAMERA_FOV - CAMERA_ZOOM, CAMERA_FOV)

	player_model.rotation_degrees.y += CAMERA_ZOOM_RATE if (current_state == State.AIM || current_state == State.SHOOT) else -CAMERA_ZOOM_RATE
	player_model.rotation_degrees.y = clamp(player_model.rotation_degrees.y, 180, 185)

func handle_shooting():
	current_gun.shoot_gun()
	# Shoot animation handler
	player_anim_tree.set("parameters/shoot/active", true)

func _input(event):
	if !in_menu && event is InputEventMouseMotion:

		rotation_degrees.y -= event.relative.x * MOUSE_SENSITIVITY

		is_rotating = abs(event.relative.x) > 5

		camera_pivot.rotation_degrees.x -= event.relative.y * MOUSE_SENSITIVITY
		camera_pivot.rotation_degrees.x = clamp(camera_pivot.rotation_degrees.x, MIN_PITCH, MAX_PITCH)

		ik_spine_target.rotation_degrees.x += event.relative.y * MOUSE_SENSITIVITY
		ik_spine_target.rotation_degrees.x = clamp(ik_spine_target.rotation_degrees.x, MIN_PITCH, MAX_PITCH)
	
func _physics_process(delta):
	handle_movement_input()
	handle_movement()

func handle_movement_input():
	direction = Vector3()

	is_getting_move_input = false

	if !in_menu:

		if Input.is_action_pressed("move_forward"):
			direction -= transform.basis.z
			walk_anim_vector = walk_anim_vector.linear_interpolate((Vector2.UP), 0.1)
			is_getting_move_input = true

		if Input.is_action_pressed("move_backward"):
			direction += transform.basis.z
			walk_anim_vector = walk_anim_vector.linear_interpolate(Vector2.DOWN, 0.1)
			is_getting_move_input = true

		if Input.is_action_pressed("move_left"):
			direction -= transform.basis.x
			walk_anim_vector = walk_anim_vector.linear_interpolate(Vector2.LEFT, 0.1)
			is_getting_move_input = true

		if Input.is_action_pressed("move_right"):
			direction += transform.basis.x
			walk_anim_vector = walk_anim_vector.linear_interpolate(Vector2.RIGHT, 0.1)
			is_getting_move_input = true

	if !is_getting_move_input:
		walk_anim_vector = walk_anim_vector.linear_interpolate(Vector2.ZERO, 0.1)

	direction = direction.normalized()

func handle_movement():
	velocity = direction * (SPEED if !(current_state == State.AIM || current_state == State.SHOOT) else SPEED/3)

	if is_on_floor():
		y_velocity = 0
	else:
		y_velocity = clamp(y_velocity - GRAVITY, -MAX_TERMINAL_VELOCITY, MAX_TERMINAL_VELOCITY)

	velocity.y = y_velocity

	if !(direction.length() == 0 && is_on_floor()):
		velocity = move_and_slide_with_snap(velocity, -Vector3.UP, Vector3.UP, true)

func handle_anim():
	# Walk animation handler
	walk_progression += (WALK_PROGRESSION_RATE if (direction.length() != 0 || is_rotating) else -WALK_PROGRESSION_RATE)
	walk_progression = clamp(walk_progression, 0, 1)
	player_anim_tree.set("parameters/lb_idle_blendspace/blend_position", walk_anim_vector)
	player_anim_tree.set("parameters/lb_aim_blendspace/blend_position", walk_anim_vector)
	player_anim_tree.set("parameters/upper_lower_blend/blend_amount", walk_progression)
	player_anim_tree.set("parameters/walk_sway_blend/blend_amount", walk_progression)

func handle_audio():
	# Footsteps
	if (is_rotating || walk_progression > 0.5) && is_on_floor():
		if (current_state == State.AIM || current_state == State.SHOOT):
			if !slow_footstep_audio.playing:
				slow_footstep_audio.play()
		else:
			if !med_footstep_audio.playing:
				med_footstep_audio.play()
	elif slow_footstep_audio.playing:
		slow_footstep_audio.stop()
	elif med_footstep_audio.playing:
		med_footstep_audio.stop()
	
func _reload_animation_step():
	reload_step_complete = true
