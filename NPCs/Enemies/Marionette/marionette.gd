extends KinematicBody

## CONSTANTS ##
# Vision
export var HEAD_SPEED = 100.0
export var VIS_ARC = 100.0
export var DECT_RADIUS = 13
export var CHASE_RADIUS = 15
# Movement
var GRAVITY : float = ProjectSettings.get_setting("physics/3d/default_gravity")
export var MAX_TERMINAL_VELOCITY : float = 980
export var ROTATION_SPPED = 200.0
export var CHAR_RADIUS = 0.82
export var CHAR_HEIGHT = 0.82
export var MIN_DIST_TO_CHECK_LOS = 100.0
# Stats
export var MAX_HP : int = 225
export var BASE_DMG : int = 50
export var MOVEMENT_SPEED : float = 10
# Attack variables
export var ATTACK_DISTANCE = 2.5
export var ATTACK_COOLDOWN = 0.5
export var ATTACK_HIT_TIME = 0.5
var is_attacking : bool = false
# FSM Points
enum State {IDLE, TRANSFORM, CHASE, SEARCH, RETURN, DEAD, ATTACK}


## NODES ##
# Vision
onready var head_movement_y = $MarionetteModel/Skeleton/HeadMovementTargetY
onready var head_movement_x = $MarionetteModel/Skeleton/HeadMovementTargetY/HeadMovementTargetX
onready var head_movement_ik = $MarionetteModel/Skeleton/HeadMovement
onready var collision_shape = $CollisionShape
onready var model = $MarionetteModel
onready var attack_cooldown_timer = $AttackCooldownTimer
onready var attack_hit_timer = $AttackHitTimer
onready var attack_hitbox = $MarionetteModel/Attack_Hitbox
var cam_target : Spatial
# Animation
onready var anim_tree = $AnimationTree
var anim_fsm
# Movement
var pm_target : Spatial
var nav : Navigation

## VARIABLES ##
# Stats
var current_hp = MAX_HP
# Vision
var is_looking : bool = false
var has_seen_player : bool = false
var cam_transform :Transform
var player_is_looking : bool = false
var in_sight_radius : bool = false
# Combat
var is_agro : bool = false
var can_attack : bool = false
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
# Misc regex
var regexHitName
var regexHead

func _ready():
	# Get external scene nodes
	anim_fsm = anim_tree.get("parameters/monster_fsm/playback")
	pm_target = get_tree().get_nodes_in_group("targets")[1]
	cam_target = get_tree().get_nodes_in_group("targets")[0]
	nav = get_tree().get_nodes_in_group("navigation")[0]

	# Start the inverse kinematics of the head for aiming
	head_movement_ik.start()

	# Sets up the Regex for points of interest for the hitbox.
	regexHitName = RegEx.new()
	regexHitName.compile("(Vine)|(Face)")
	regexHead = RegEx.new()
	regexHead.compile("(Head)|(Face)")

	# Set up attack timers infos
	attack_cooldown_timer.wait_time = ATTACK_COOLDOWN
	attack_hit_timer.wait_time = ATTACK_HIT_TIME
	attack_hit_timer.connect("timeout", self, "_attack_timer_event")

func _process(delta):
	# Get the player's camera position
	cam_transform = cam_target.global_transform

	# Determine if the monster can attack
	can_attack = \
		pm_target.global_transform.origin.distance_to(global_transform.origin) < ATTACK_DISTANCE && \
		attack_cooldown_timer.time_left == 0 && \
		attack_hitbox.get_overlapping_bodies().size() > 0 && \
		PlayerInfo.current_hp > 0

	handle_vision(delta)
	handle_agro()
	handle_state()

# Handles the agro of the monster
func handle_agro():
	if is_agro:
		pass
	else:
		is_agro = has_seen_player && \
			!(player_is_looking && is_looking && in_sight_radius)
	

func _physics_process(delta):
	handle_movement(delta)

# Handles the finite state machine of the monster
func handle_state():
	# ANY -> DEAD
	if current_state != State.DEAD && current_hp <= 0:
		handle_death()
		current_state = State.DEAD
	match current_state:
		State.IDLE:
			# IDLE -> CHASE
			if is_agro:
				anim_fsm.travel("idle_low")
				head_movement_ik.stop()
				current_state = State.TRANSFORM
				
		State.TRANSFORM:
				#TRANSFORM -> CHASE
				if(anim_fsm.get_current_node() == "idle_low"):
					current_state = State.CHASE

		State.CHASE:
			# CHASE -> SEARCH
			if !is_looking:
				current_state = State.SEARCH
			# CHASE -> ATTACK
			elif can_attack:
				attack()
				current_state = State.ATTACK
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
		State.ATTACK:
			# ATTACK -> CHASE
			if(anim_fsm.get_current_node() == "idle_low"):
				is_attacking = false
				attack_cooldown_timer.start()
				current_state = State.IDLE
			pass

# Function attack is called when moving from chase to attack. Sets the attack
# flag, sets the hit timer (which eventually runs attack_timer_event), and starts
# the animation.
func attack():
	is_attacking = true
	attack_hit_timer.start()
	anim_fsm.travel("attack")

# Triggered by the attack timer hit to have the hit determined when the animation
# lines up with a hit.
func _attack_timer_event():
	var bodies = attack_hitbox.get_overlapping_bodies()
	for body in bodies:
		if body.has_method("_take_damage"):
			body._take_damage(BASE_DMG, "slash")

# Handles the vision of the monster.
func handle_vision(delta):
	# If the player is in the line of sight of the monster, is in the vision cone,
	# and is in the sight radius, the monster will now look at the player
	is_looking = head_movement_x.has_los(pm_target.global_transform.origin) && \
	head_movement_x.in_vision_cone(pm_target.global_transform.origin, VIS_ARC) && \
	head_movement_x.is_in_radius(pm_target.global_transform.origin, DECT_RADIUS)

	# If the monster is looking at the player, trigger the has_seen_player flag
	# and update the last known position.
	if(is_looking):
		pm_last_known_pos = pm_target.global_transform.origin
		has_seen_player = true

	# If the player was ever seen, make the monster look at the last known
	# position.
	if(has_seen_player):
		head_movement_y.face_point(pm_last_known_pos, delta, HEAD_SPEED)
		head_movement_x.face_point(pm_last_known_pos, delta, HEAD_SPEED)

	# Determine if the player is looking at the monster
	player_is_looking = \
		head_movement_x.player_is_looking(cam_transform.origin, cam_transform.basis.z, 90)

	# Determine if the player is in the sight radius of the monster
	in_sight_radius = \
		head_movement_x.is_in_radius(pm_target.global_transform.origin, CHASE_RADIUS)

# Handles the movement of the monster using the path finding handler
func handle_movement(delta):
	# Deny movmenet and rotation if it is neither searchign nor chasing
	if !(current_state == State.CHASE || current_state == State.SEARCH):
		return

	# Rotate regardless of if it should move
	collision_shape.face_point(pm_target.global_transform.origin, \
	                           delta, ROTATION_SPPED)
	model.face_point(pm_target.global_transform.origin, delta, ROTATION_SPPED)

	# Only move if it is chasing/searching and if it is not in hitting distance
	var should_move = \
		!pm_target.global_transform.origin.distance_to(global_transform.origin) \
		< ATTACK_DISTANCE
	if(should_move):
		# Update the movement vector of the monster using the pathfinding node
		update_move_vec()
		# If the velocity of the movement is less than 0.1, trigger the movement
		# animation. Otherwise trigger the idle movement.
		if velocity.length() > 0.1:
			anim_fsm.travel("move")
		else:
			anim_fsm.travel("idle_low")
		# Move using the velocity vector.
		move_and_slide(velocity * MOVEMENT_SPEED, Vector3.UP)

# Function called from the shotgun when the player fires it.
func _bullet_hit(_damage, _part, _pos):
	is_agro = true
	var isHead = regexHead.search(_part)
	var damage = _damage * 2 if isHead else _damage
	current_hp -=  damage

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
		velocity = our_pos.direction_to(target_pos)
		velocity = velocity.normalized()
	elif path_ind < path.size():
		var next_path_pos = path[path_ind]
		while our_pos.distance_squared_to(next_path_pos) < 0.1 * 0.1 and path_ind < path.size() - 1:
			path_ind += 1
			next_path_pos = path[path_ind]
		velocity = our_pos.direction_to(next_path_pos)
		velocity = velocity.normalized()
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

func apply_gravity():
		var g_vel = Vector3()
		if is_on_floor():
			g_vel = -get_floor_normal() * GRAVITY
		else:
			g_vel.y -= GRAVITY
			g_vel.y = clamp(g_vel.y, -MAX_TERMINAL_VELOCITY, MAX_TERMINAL_VELOCITY)
		return g_vel

func handle_death():
	anim_fsm.travel("death")
	self.set_process(false)
	self.set_physics_process(false)
