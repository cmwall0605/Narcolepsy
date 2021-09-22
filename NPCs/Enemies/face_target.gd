extends Spatial

var los = false
var check_this_frame = false

func _ready():
	check_this_frame = randi() % 2 == 0

func face_point(point: Vector3, delta: float, speed: float):
	var l_point = to_local(point)
	l_point.y = 0.0
	var turn_dir = -sign(l_point.x)
	var turn_amnt = deg2rad(speed * delta)
	var angle = Vector3.BACK.angle_to(l_point)

	if angle < turn_amnt:
		turn_amnt = angle
	rotate_object_local(Vector3.UP, -turn_amnt * turn_dir)

func in_vision_cone(point: Vector3, arc_size: float):
	var fwd = global_transform.basis.z
	var dir_to_point = point - global_transform.origin
	return rad2deg(dir_to_point.angle_to(fwd)) <= arc_size/2.0

func is_in_radius(point: Vector3, radius: float):
	return global_transform.origin.distance_to(point) <= radius

func has_los(point: Vector3):
	check_this_frame = !check_this_frame
	if !check_this_frame:
		return los
	var space_state = get_world().direct_space_state
	var result = space_state.intersect_ray(global_transform.origin, point, [], 8)
	los = result.size() == 0
	return los

func player_is_looking(point: Vector3, vector: Vector3, fov: float):
	var p2m_vector = point - global_transform.origin
	return rad2deg(p2m_vector.angle_to(vector)) <= fov/2.0
	