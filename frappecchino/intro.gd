extends Control
	
@onready var animation_player: AnimationPlayer = $CanvasLayer/AnimationPlayer
@onready var video_stream_player: VideoStreamPlayer = $Node2D/VideoStreamPlayer
@onready var skip_animation: AnimationPlayer = $CanvasLayer/SkipAnimation
@onready var label: Label = $CanvasLayer/Label
@onready var audio_stream_player: AudioStreamPlayer = $Node2D/AudioStreamPlayer

var skipped: bool = false

func _ready() -> void:
	label.modulate.a = 0.0
	animation_player.play_backwards("fade_out")
	await animation_player.animation_finished
	skip_animation.play("skip_fade_out")
	video_stream_player.play()
	audio_stream_player.play()
	
func _process(_delta) -> void:
	if Input.is_action_just_pressed("skip") and not skipped and skip_animation.assigned_animation == "skip_fade_out":
		end()

func _on_video_stream_player_finished() -> void:
	if not skipped:
		end()

func end() -> void:
	skipped = true
	if skip_animation.current_animation_position < 3.25:
		skip_animation.seek(3.25, true)
		skip_animation.play_section()
	animation_player.play("fade_out")
	await animation_player.animation_finished
	label.modulate.a = 0.0
	get_tree().change_scene_to_file("res://tutorial.tscn")
