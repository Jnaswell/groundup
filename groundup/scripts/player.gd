extends CharacterBody3D
@onready var stand_collision_shape: CollisionShape3D = $stand_collision_shape
@onready var crouch_collision_shape: CollisionShape3D = $crouch_collision_shape
@onready var head: Node3D = $head
@onready var camera_3d: Camera3D = $head/Camera3D
@onready var ray_cast_3d: RayCast3D = $RayCast3D
@onready var interaction: RayCast3D = $head/Camera3D/interaction
@onready var hand: Marker3D = $head/Camera3D/hand
@onready var generic_6dof_joint_3d: Generic6DOFJoint3D = $head/Camera3D/Generic6DOFJoint3D
@onready var static_body_3d: StaticBody3D = $head/Camera3D/StaticBody3D
@onready var camera_zoom: Camera3D = $head/Camera3D
@onready var gun_barrel: RayCast3D = $head/Camera3D/gun_hand/gungoshoot/gun_barrel
@onready var fire_delay_timer: Timer = $fire_delay_timer
@onready var ammo_bar: ProgressBar = $head/Camera3D/gun_hand/gungoshoot/ammo/SubViewport/ammo_bar
@onready var health_bar: ProgressBar = $head/Camera3D/gun_hand/gungoshoot/health/SubViewport/health_bar
@onready var cool_down_delay_timer: Timer = $cool_down_delay
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@export var cool_down_delay: = 3.0
@export var fire_delay: float = 0.15
@export_group("zoom")
@export var zoom_fov: float = 40.0
@export var zoom_speed: float = 4.0
@onready var default_fov: float = camera_zoom.fov

#variables
var player_health = 5
var ammo = 10
var instance
var picked_object
var pull_power = 5.0
var current_speed = 5.0
var lerp_speed = 10.0
var direction = Vector3.ZERO
var crouching_depth = -0.5
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var rotation_power = 1.5
var locked = false
var bullet  = preload("res://guns_ammo_health/bullet.tscn")
# head bobbing vars

#constants
const walking_speed = 5.0
const sprinting_speed = 10.0
const crouching_speed = 3.0
const jump_velocity = 4.5
const mouse_sens = 0.15

#functions
func _input(event):
	if locked:
		rotate_object(event)

func rotate_object(event):
	if picked_object != null:
		if event is InputEventMouseMotion:
			static_body_3d.rotate_x(deg_to_rad(event.relative.y * rotation_power))
			static_body_3d.rotate_y(deg_to_rad(event.relative.x * rotation_power))
		
func pick_object():
	var collider = interaction.get_collider()
	if collider != null and collider is RigidBody3D:
		picked_object = collider
		generic_6dof_joint_3d.set_node_b(picked_object.get_path())
	
func remove_object():
	if picked_object != null:
		picked_object = null
		generic_6dof_joint_3d.set_node_b(generic_6dof_joint_3d.get_path())
		
func _process(delta):
	
	if Input.is_action_pressed("zoom"):
		camera_zoom.set_fov(lerp(camera_zoom.fov, zoom_fov, delta * zoom_speed))
	elif camera_zoom.fov != default_fov:
		camera_zoom.set_fov(lerp(camera_zoom.fov, default_fov, delta * zoom_speed))
	
func _ready():
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	
func _unhandled_input(event: InputEvent):
	
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().change_scene_to_file("res://scenes/Start.tscn")
	
	if Input.is_action_pressed("pickup"):
		if picked_object == null:
			pick_object()
		elif picked_object != null:
			remove_object()
	
	if Input.is_action_pressed("rotate"):
		locked = true
		rotate_object(event)
	if Input.is_action_just_released("rotate"):
		locked = false
		
	if event is InputEventMouseMotion && !locked:
		
		rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
		head.rotate_x(deg_to_rad(-event.relative.y * mouse_sens))
		head.rotation.x = clamp(head.rotation.x,deg_to_rad(-69),deg_to_rad(69))
	
func _physics_process(delta):
	
	if interaction.is_colliding():
		var target = interaction.get_collider()
		print(target)
	
	health_bar.value = player_health
	if player_health < 1:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().change_scene_to_file("res://scenes/Start.tscn")
		
	
	ammo_bar.value = ammo
	if ammo > 10:
		ammo = 10
	if ammo > 0:
		ammo += delta * 1
	if ammo < 0:
		fire_delay_timer.start(fire_delay)
		ammo += delta * 1
		
	if Input.is_action_pressed("shoot") and fire_delay_timer.is_stopped():
			
			fire_delay_timer.start(fire_delay)
			ammo -= 1
			instance = bullet.instantiate()
			instance.position = gun_barrel.global_position
			instance.transform.basis = gun_barrel.global_transform.basis
			get_parent().add_child(instance)
	
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	
	if Input.is_action_just_pressed("throw"):
		if picked_object != null:
			var knockback = picked_object.position - position
			picked_object.apply_central_impulse(knockback * 4)
			remove_object()
		
	if Input.is_action_pressed("crouch"):
		current_speed = crouching_speed
		head.position.y = lerp(head.position.y,1.8 + crouching_depth,delta*lerp_speed)
		stand_collision_shape.disabled = true
		crouch_collision_shape.disabled = false
		
		
	elif !ray_cast_3d.is_colliding():
		
		stand_collision_shape.disabled = false
		crouch_collision_shape.disabled = true
		
		head.position.y = lerp(head.position.y,1.8,delta*lerp_speed)
		
		if Input.is_action_pressed("sprint"):
		
			current_speed = sprinting_speed
		
		else:
			current_speed = walking_speed
		
	if picked_object != null:
		var a = picked_object.global_transform.origin
		var b = hand.global_transform.origin
		picked_object.set_linear_velocity((b-a)*pull_power)
	
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	
	direction = lerp(direction,(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(),delta * lerp_speed)
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
	
	move_and_slide()
	
func _on_area_3d_body_entered(body):
	if body.is_in_group("enemy"):
		animation_player.play("take_damage")
		player_health -= 1
