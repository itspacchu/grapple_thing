extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 4.5
@onready var camera = $Camera3D
var SENS = 0.0005
var decal = null

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * SENS)
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
	return space.intersect_ray(ray_query)

func handle_spray(raypoint):
	if(raypoint):
		if(decal == null):
			decal = Decal.new()
			decal.texture_albedo = load("res://Pngs/mercy.png")
			get_parent().add_child(decal)
			print(raypoint)
		else:
			decal.texture_albedo = load("res://Pngs/mercy.png")
			decal.position = raypoint["position"]
			decal.rotate(raypoint["normal"],PI/2*raypoint["normal"].length())

func _physics_process(delta):
	if(Input.is_action_just_pressed("spray")):
		var raypoint = get_collision_point()
		handle_spray(raypoint)
			
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED*delta*10)
		velocity.z = move_toward(velocity.z, 0, SPEED*delta*10)

	move_and_slide()
	
