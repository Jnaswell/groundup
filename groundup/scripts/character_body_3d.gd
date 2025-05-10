extends CharacterBody3D

@onready var player = get_tree().get_first_node_in_group("player")
@onready var isChasing: bool
@onready var isSearching: bool
@onready var character_body_3d: CharacterBody3D = $CharacterBody3D
@onready var radar: int = 0
@onready var ray_cast_3d: RayCast3D = $RayCast3D
@onready var nav := $NavigationAgent3D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var gpu_particles_3d: GPUParticles3D = $GPUParticles3D
@onready var random_pos = Vector3(randf_range(-50.0, 25.0), position.y, randf_range(-60.0, 35.0))

var raycast = true
var lastPos
var hasSeen : bool
var health = 10
var timer = 1.0
@onready var walkingSpeed = 2
@onready var chasingSpeed = 4
@onready var speed = chasingSpeed

@onready var wanderTimer = 2.0

func _process(delta):
	if Input.is_action_pressed("shoot"):
		isChasing = true
	
	if isChasing:
		chase()
		speed = chasingSpeed
	else:
		speed = walkingSpeed
		wandering(delta)
		
	var direction = nav.get_next_path_position() - global_position
	direction = direction.normalized()
	
	velocity = velocity.lerp(direction * speed, delta * 10)
	
	move_and_slide()
	
func chase():
	look_at(player.position)
	nav.target_position = player.global_position
	
func wandering(delta):
	look_at(global_transform.origin + velocity)
	hasSeen = false
	nav.target_position = random_pos
	if (abs(random_pos.x - global_position.x) <= 5 and abs(random_pos.z - global_position.z) <= 5):
		random_pos = Vector3(randf_range(player.global_position.x-40.0, player.global_position.x+40.0), position.y, randf_range(player.global_position.z-40.0, player.global_position.z+40.0))
		clamp(random_pos.x, -50.0, 25.0)
		clamp(random_pos.z, -60.0, 35.0)
		wanderTimer -= delta
	
func _on_detector_body_entered(body):
	if body.is_in_group("player"):
		isChasing = true
	
	
func _on_detector_body_exited(body):
	if body.is_in_group("player"):
		lastPos = body.global_position
		random_pos = lastPos
		isChasing = false
	
func _on_area_3d_area_entered(area: Area3D):
	if area.is_in_group("bullet"):
		animation_player.play("take_damage")
		isChasing = true
		random_pos
		health -= 1
		if health <= 0:
			gpu_particles_3d.emitting = true
			animation_player.play("die")
			await get_tree().create_timer(1.0).timeout
			queue_free()
			
func _on_timer_timeout():
	queue_free()
	
func _on_area_3d_body_entered(body):
	if body.is_in_group("player"):
		player.player_health -= 1
