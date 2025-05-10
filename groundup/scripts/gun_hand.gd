extends Node3D

const ads_lerp = 20

@export var default_positon: Vector3
@export var ads_position: Vector3
	
	
	
func _process(delta):
	if Input.is_action_pressed("aim"):
	
		transform.origin = transform.origin.lerp(ads_position, ads_lerp * delta)
	else:
		transform.origin = transform.origin.lerp(default_positon, ads_lerp * delta)
