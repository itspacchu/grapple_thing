extends RigidBody3D

var _pid := PID.new(4.0,0.5,0.0)
const MAX_SPEED:float = 15.0
const JUMP_VELOCITY:float = 4.5
var SENS:float = 0.001
var MAX_GRAPPLE:float = 50
var GRAPPLE_FORCE:float = 0.1
@onready var camera = $Head/Camera3D
var decal = null
var grapple_point = null
var raydist:float = 0.0

var _velo_buff:float = 0;

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		$Head.rotate_y(-event.relative.x * SENS)
		camera.rotate_x(-event.relative.y * SENS)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)

func get_collision_point():
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_length = 1000
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * ray_length
	var space = get_world_3d().direct_space_state
	var ray_query = PhysicsRayQueryParameters3D.new()
	ray_query.from = from
	ray_query.to = to
	ray_query.collide_with_areas = true
	var returnable:= space.intersect_ray(ray_query)
	if(returnable):
		$gpoint.global_position = returnable["position"]
	return returnable

func handle_spray(raypoint):
	if(raypoint):
		if(decal == null):
			decal = Decal.new()
			decal.texture_albedo = load("res://Pngs/mercy.png")
			decal.size.y = 0.01
			get_parent().add_child(decal)
			print(raypoint)
		else:
			decal.texture_albedo = load("res://Pngs/mercy.png")
			decal.position = raypoint["position"]
			var hitnormal = raypoint["normal"]
			#if hitnormal != Vector3.UP:
			decal.look_at(decal.position+Vector3.UP, hitnormal)
			#decal.rotate(raypoint["normal"],PI/2*raypoint["normal"].length())

func _process(delta):
	if(Input.is_key_pressed(KEY_R)):
		get_tree().reload_current_scene()
	camera.fov = clamp(remap(linear_velocity.length(),0,50,75,105),75,105)
	if(linear_velocity.length() > 15):
		$Control/crosshair/GPUParticles2D.emitting = true
	else:
		$Control/crosshair/GPUParticles2D.emitting = false
		
	if(Input.is_action_just_pressed("spray")):
		var raypoint = get_collision_point()
		handle_spray(raypoint)
	
	if Input.is_key_pressed(KEY_F):
		_pid._reset_integral()

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		_pid._reset_integral()
		apply_central_impulse(JUMP_VELOCITY * mass * Vector3(0, 1, 0))
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = ($Head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var desired_velocity = MAX_SPEED * direction
	var velocity_error = desired_velocity - linear_velocity
	velocity_error.y = 0.0
	var correction_impulse = mass * _pid.update(velocity_error, delta) * 1e-2
	correction_impulse = correction_impulse.normalized() * min(correction_impulse.length(), 1.0)
	
	if(Input.is_action_just_pressed("sprint")):
		correction_impulse *= 10
	apply_central_impulse(correction_impulse)
	
	var raycast = get_collision_point()

	if(raycast):
		raydist = (raycast["position"]-position).length()
		if(raydist < MAX_GRAPPLE):
			$Control/crosshair/distanceLabel.text = "%d m" % raydist
			$Control/crosshair.self_modulate = Color.WHITE
		else:
			$Control/crosshair/distanceLabel.text = "---" % raydist
			$Control/crosshair.self_modulate = Color.RED
	else:
		raydist = 0
	
	if(Input.is_action_just_pressed("fire")):
		if(raydist > MAX_GRAPPLE):
			grapple_point = null
			
		else:
			grapple_point = raycast
			

	if Input.is_action_pressed("fire"):
		_pid._reset_integral()
		if(grapple_point):
			var force = (grapple_point["position"] - position).normalized()
			var distance = clamp((grapple_point["position"] - position).length(),0,MAX_GRAPPLE)
			apply_central_impulse(GRAPPLE_FORCE*distance*force)
			$Head/Camera3D/CamAttach/PulsePistols.look_at(grapple_point["position"])
			$Head/Camera3D/CamAttach/PulsePistols/Armature001/Skeleton3D.set_bone_pose_position(1,Vector3.UP*distance*2)
	else:
		$Head/Camera3D/CamAttach/PulsePistols/Armature001/Skeleton3D.set_bone_pose_position(1,Vector3.UP*(-1))
		$Head/Camera3D/CamAttach/PulsePistols.rotation_degrees = lerp($Head/Camera3D/CamAttach/PulsePistols.rotation_degrees,Vector3.ZERO,delta*10)	



