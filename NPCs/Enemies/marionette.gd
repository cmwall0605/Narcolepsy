extends KinematicBody

## CONSTANTS ##
# Vision
export var HEAD_SPEED = 100.0
export var VIS_ARC = 100.0
export var DECT_RADIUS = 13
export var CHASE_RADIUS = 15

# Movement
export var GRAVITY : float = 900
export var MAX_TERMINAL_VELOCITY : float = 9000

export var CHAR_RADIUS = 0.82
export var CHAR_HEIGHT = 0.82
export var MIN_DIST_TO_CHECK_LOS = 20.0

# Stats
export var HP : int = 225
export var BASE_DMG : int = 50
export var MOVEMENT_SPEED : float = 360.0

# FSM Points
enum State {IDLE, CHASE, SEARCH, RETURN, DEAD}


## NODES ##
# Vision
onready var head_movement_y = $MarionetteModel/Skeleton/HeadMovementTargetY
onready var head_movement_x = $MarionetteModel/Skeleton/HeadMovementTargetY/HeadMovementTargetX
onready var head_movement_ik = $MarionetteModel/Skeleton/HeadMovement
onready var collision_shape = $CollisionShape
onready var model = $MarionetteModel
var cam_target : Spatial
# Animation
onready var anim_tree = $AnimationTree
var anim_fsm
# Movement
var pm_target : Spatial
var nav : Navigation

## VARIABLES ##
# Vision
var is_looking : bool = false
var has_seen_player : bool = false
var cam_transform :Transform
# Combat
var is_shot : bool = false
# Movement
var pm_last_known_pos : Vector3
var	searched_last_pos : bool = false
var is_at_origin : bool = false
var velocity : Vector3 = Vector3.ZERO
var path = []
var path_ind = 0
var last_straight_line_check = false
var has_hit_ground = false
# State
var current_state = State.IDLE

func _ready():
	anim_fsm = anim_tree.get("parameters/monster_fsm/playback")
	pm_target = get_tree().get_nodes_in_group("targets")[1]
	cam_target = get_tree().get_nodes_in_group("targets")[0]
	nav = get_tree().get_nodes_in_group("navigation")[0]
	head_movement_ik.start()

func _process(delta):
	cam_transform = cam_target.global_transform

	handle_vision(delta)
	handle_state()

func _physics_process(delta):
	handle_movement(delta)

func handle_state():
	# ANY -> DEAD
	if current_state != State.DEAD && HP <= 0:
		handle_death()
		current_state = State.DEAD
	match current_state:
		State.IDLE:
			# IDLE -> CHASE
			if is_shot || (has_seen_player && !head_movement_x.player_is_looking(cam_transform.origin, cam_transform.basis.z, 90)):
				anim_fsm.travel("idle_low")
				head_movement_ik.stop()
				current_state = State.CHASE
			# IDLE -> SEARCH
			elif has_seen_player && !(is_looking && head_movement_x.is_in_radius(pm_target.global_transform.origin, CHASE_RADIUS)):
				anim_fsm.travel("idle_low")
				head_movement_ik.stop()
				current_state = State.SEARCH
		State.CHASE:
			# CHASE -> SEARCH
			if !is_looking:
				current_state = State.SEARCH
		State.SEARCH:
			# SEARCH -> CHASE
			if is_looking:
				current_state = State.CHASE
			# SEARCH -> RETURN
			elif searched_last_pos:
				current_state = State.RETURN
		State.RETURN:
			# RETURN -> CHASE
			if is_looking:
				current_state = State.CHASE
			# RETURN -> IDLE
			elif is_at_origin:
				current_state = State.IDLE

func handle_vision(delta):
	is_looking = head_movement_x.has_los(pm_target.global_transform.origin) && \
	head_movement_x.in_vision_cone(pm_target.global_transform.origin, VIS_ARC) && \
	head_movement_x.is_in_radius(pm_target.global_transform.origin, DECT_RADIUS)

	if(is_looking):
		pm_last_known_pos = pm_target.global_transform.origin
		has_seen_player = true

	if(has_seen_player):
		head_movement_y.face_point(pm_last_known_pos, delta, HEAD_SPEED)
		head_movement_x.face_point(pm_last_known_pos, delta, HEAD_SPEED)

func handle_movement(delta):
	if(current_state == State.CHASE || current_state == State.SEARCH):
		update_move_vec()
		if velocity.length() > 0.1:
			var velocity_movement = velocity
			velocity_movement.y = 0
			anim_fsm.travel("move")
			collision_shape.face_point(pm_target.global_transform.origin, delta, HEAD_SPEED)
			model.face_point(pm_target.global_transform.origin, delta, HEAD_SPEED)
		else:
			anim_fsm.travel("idle_low")
	if !is_on_floor() || current_state == State.CHASE || current_state == State.SEARCH:
		move_and_slide_with_snap(velocity * MOVEMENT_SPEED * delta, -Vector3.UP, Vector3.UP, true)

func get_target_move_pos():
	var actual_target = pm_target.global_transform.origin
	actual_target.y = 0.0
	return actual_target

func update_move_vec():
	var our_pos = global_transform.origin

	var straight_line_check = can_move_in_straight_line()

	if !straight_line_check:
		if last_straight_line_check:
			path = [get_target_move_pos()]
			path_ind = 0
		PathfindingManager.calc_path(self, nav)

	if straight_line_check:
		var target_pos = get_target_move_pos()
		velocity = our_pos.direction_to(target_pos).normalized()
	elif path_ind < path.size():
		var next_path_pos = path[path_ind]
		while our_pos.distance_squared_to(next_path_pos) < 0.1 * 0.1 and path_ind < path.size() - 1:
			path_ind += 1
			next_path_pos = path[path_ind]
		velocity = our_pos.direction_to(next_path_pos).normalized()

		last_straight_line_check = straight_line_check

func can_move_in_straight_line():
	var pos = global_transform.origin
	var target_pos = pm_target.global_transform.origin

	if pos.distance_squared_to(target_pos) > MIN_DIST_TO_CHECK_LOS*MIN_DIST_TO_CHECK_LOS:
		return false
	
	var right : Vector3 = target_pos - pos
	right = right.rotated(Vector3.UP, PI/2).normalized()
	var ray_right_start_pos = pos + right * CHAR_RADIUS
	var ray_left_start_pos = pos + -right * CHAR_RADIUS
	var ray_right_end_pos = target_pos + right * CHAR_RADIUS
	var ray_left_end_pos = target_pos + -right * CHAR_RADIUS

	var space_state = get_world().direct_space_state
	var los_left = space_state.intersect_ray(ray_left_start_pos, ray_left_end_pos, [], 8).size() == 0
	var los_right = space_state.intersect_ray(ray_right_start_pos, ray_right_end_pos, [], 8).size() == 0
	
	return los_left and los_right
	

func update_path(_path: Array):
	if _path.size() == 0:
		return
	path = _path
	path_ind = 0

func apply_gravity(delta):
	if !is_on_floor():
		velocity.y -= GRAVITY * delta
		velocity.y = clamp(velocity.y, -MAX_TERMINAL_VELOCITY, MAX_TERMINAL_VELOCITY)

func handle_death():
	anim_fsm.travel("death")
