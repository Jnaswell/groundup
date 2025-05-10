extends Control
	
func _on_start_pressed():
	get_tree().change_scene_to_file("res://scenes/groundup.tscn")
	
func _on_controls_pressed():
	get_tree().change_scene_to_file("res://scenes/controls_menu.tscn")
	
func _on_quit_pressed():
	get_tree().quit()
	
