extends Node3D
@onready var player: CharacterBody3D = $player



func _physics_process(delta):
	get_tree().call_group("enemy", "target_position", player.global_transform.origin)
