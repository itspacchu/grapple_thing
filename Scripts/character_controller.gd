extends RigidBody3D

var _pid := PID.new(4.0,0.5,0.0)

const MAX_SPEED:float = 15.0
const JUMP_VELOCITY:float = 4.5
var SENS:float = 0.001
const MAX_GRAPPLE:float = 50
const MAX_COOLDOWN = 1.5
const GRAPPLE_FORCE:float = 0.1
const SWORD_DAMAGE:float = 25
const ATTACK_COOLDOWN = 1.5

@onready var camera = $Head/Camera3D
@export var grapple_point:Dictionary = {}
var decal = null
var raydist:float = 0.0
var can_grapple:bool = true
var current_cooldown = 0
var can_attack:bool = true
@export var health = 50
@export var player_nick:String = ""

func _ready():
	if(not is_multiplayer_authority()): return
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true
	current_cooldown = MAX_COOLDOWN
	%swordimator.play("RESET")
	$GPUParticles3D.emitting = false
	$Label3D.hide()
	$HP.hide()

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())

func _unhandled_input(event):
	if(not is_multiplayer_authority()): return
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
	ray_query.collide_with_areas = false
	var returnable:= space.intersect_ray(ray_query)			
	return returnable

func handle_spray(raypoint):
	if(raypoint):
		$soundeffects.play(0.0)
		if(decal == null):
			decal = Decal.new()
			decal.texture_albedo = load("res://Pngs/wake.png")
			decal.size.y = 0.1
			get_parent().add_child(decal)
			decal.global_position = raypoint["position"]
		else:
			decal.texture_albedo = load("res://Pngs/wake.png")
			decal.global_position = raypoint["position"]
			var hitnormal = raypoint["normal"]
			#decal.look_at(camera.global_position,Vector3.UP)
			if hitnormal != Vector3.UP:
				decal.look_at(decal.position + hitnormal, Vector3.UP)
				decal.transform = decal.transform.rotated_local(Vector3.RIGHT, PI/2.0)

func reset_player():
	_pid._reset_integral()
	position = Vector3.ZERO
	rotation = Vector3.ZERO
	linear_velocity = Vector3.ZERO
	$Head.rotation = Vector3.ZERO
	camera.rotation = Vector3.ZERO
	$GPUParticles3D.emitting = false

func _process(delta):
	$Label3D.text = player_nick + "\n" + str(health)
	if(not is_multiplayer_authority()): return		
	camera.fov = clamp(remap(linear_velocity.length(),0,50,75,105),75,105)
	$Control/HSlider.value = health
	if(linear_velocity.length() > 15):
		$Control/crosshair/GPUParticles2D.emitting = true
		$Control/crosshair/GPUParticles2D.speed_scale = remap(linear_velocity.length(),10,30,2.5,6)
	else:
		$Control/crosshair/GPUParticles2D.emitting = false
		
	if(Input.is_action_just_pressed("spray")):
		var raypoint = get_collision_point()
		handle_spray(raypoint)
	
	if(Input.is_action_just_pressed("fire") and can_attack):
		can_attack = false
		%grapple.set_pressed_no_signal(false)	
		%swordimator.play("Swhing")
		%swordimator.speed_scale = 1/ATTACK_COOLDOWN
		$AttackCoolDown.start(ATTACK_COOLDOWN)
		%slash.set_pressed_no_signal(true)
		%slash.disabled = true	
		var hit_things = $Head/Camera3D/lethalArea.get_overlapping_bodies() + $Head/Camera3D/nonlethal.get_overlapping_bodies()
		hit_things.erase(self)	
		for players_hit in hit_things:
			if(players_hit.is_in_group("Player")):
				if(players_hit.health == 25):
					var msg = preload("res://label.tscn").instantiate()
					msg.writeText("You Killed %s" % players_hit.player_nick)
					add_child(msg)
				players_hit.take_damage.rpc_id(players_hit.get_multiplayer_authority())
				
				
		
	if($AttackCoolDown.is_stopped()):
		%slash.text = "S"
	else:
		if($AttackCoolDown.time_left == ATTACK_COOLDOWN - 1):
			%swordimator.play("RESET")
		%slash.text = "%d" % $AttackCoolDown.time_left
	
	if($GrappleCooldown.is_stopped()):
		%grapple.text = "G"
	else:
		%grapple.text = "%d" % $GrappleCooldown.time_left
		
	if(Input.is_key_pressed(KEY_R)):
		reset_player()
	
		

func _physics_process(delta: float) -> void:
	if(not is_multiplayer_authority()): return
	if(Input.is_action_pressed("ui_accept") and get_contact_count() and get_collision_point()):
		_pid._reset_integral()
		var normal:Vector3 = get_collision_point()["normal"]
		if(abs(normal.dot(Vector3(1,0,1))) > 0.5):
			apply_central_impulse(0.065 * JUMP_VELOCITY * mass * (Vector3.UP))
		elif(normal.y > 0):
			apply_central_impulse(JUMP_VELOCITY * mass * Vector3.UP)
			
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
			$Control/crosshair.self_modulate = Color.RED
	else:
		raydist = 0
	
	if(Input.is_action_just_pressed("grapple")):
		if(raydist > MAX_GRAPPLE):
			grapple_point = {}
			
		else:
			grapple_point = raycast
			
	if(Input.is_action_just_released("grapple")):
		%grapple.set_pressed_no_signal(false)
		if(grapple_point != {}):
			$GrappleCooldown.start(MAX_COOLDOWN)
			%grapple.disabled = true
			can_grapple = false
		grapple_point = {}
	
	if(Input.is_action_pressed("grapple") and can_grapple):
		%grapple.set_pressed_no_signal(true)
		_pid._reset_integral()
		if(grapple_point):
			if(not grapple_point["collider"].is_in_group("Player")):	
				var force = (grapple_point["position"] - position).normalized()
				var distance = clamp((grapple_point["position"] - position).length(),0,MAX_GRAPPLE)
				apply_central_impulse(GRAPPLE_FORCE*distance*force)
				$Head/Camera3D/CamAttach/PulsePistols.look_at(grapple_point["position"])
				%rope.scale.z = lerp(%rope.scale.z,distance*2,delta*5)
		
	else:
		%rope.scale.z = lerp(%rope.scale.z,0.0,delta*50)
		$Head/Camera3D/CamAttach/PulsePistols.rotation_degrees = lerp($Head/Camera3D/CamAttach/PulsePistols.rotation_degrees,Vector3.ZERO,delta*10)	



func _on_grapple_cooldown_timeout():
	can_grapple = true
	%grapple.disabled = false
	$GrappleCooldown.stop()

@rpc("any_peer")
func take_damage():
	$GPUParticles3D.emitting = true
	self.health -= SWORD_DAMAGE
	if(health <= 0):
		health = 50
		$DeadCam/Respawning.start(3)
		visible = false
		$DeadCam.visible = true

func _on_attack_cool_down_timeout():
	$AttackCoolDown.stop()
	can_attack = true
	%slash.disabled = false
	%swordimator.play("RESET")


func _on_respawning_timeout():
	$DeadCam.visible = false
	$DeadCam/Respawning.stop()
	visible = true
	reset_player()
