extends Control
	
func _process(_delta) -> void:
	if Input.is_anything_pressed():
		get_tree().change_scene_to_file("res://game.tscn")

func _on_video_stream_player_finished() -> void:
	get_tree().change_scene_to_file("res://game.tscn")
