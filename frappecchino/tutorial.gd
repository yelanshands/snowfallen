extends Node3D

@onready var barrier1 = $building/innerwalls/barrier1
@onready var barrier2 = $building/innerwalls/barrier2
@onready var finalbarrier = $building/innerwalls/finalbarrier
@onready var n1 = $n1
@onready var n2 = $n2
@onready var n3 = $n3
@onready var n4 = $n4
@onready var slide1 = $slide1
@onready var slide2 = $slide2
@onready var finalnpc = $finalnpc
@onready var dialogue_box: CanvasLayer = $Dialogue
@onready var dialogue_text: Label = $Dialogue/DialogueBorder/DialogueBox/HBoxContainer/VBoxContainer/Dialogue
@onready var animation: AnimationPlayer = $AnimationPlayer
@onready var timer: Timer =  $building/Node/DialogueTimer
@onready var player: CharacterBody3D = $Player

@export var text_speed: float = 0.015

var player_respawn: Vector3

var range_enemies: Array
var slide_enemies: Array
var final_enemies: Array
var current_dialogue_id = 0

var area0text = "Hurry, before the explosion goes off. Use WASD to move. Jump moving forward and pressing SPACE."
var area1text = "Shoot the targets with LEFT CLICK. Notice how headshots deal more damage than body shots? And body shots deal more than leg shots?"
var area2text = "Slide under by moving forward and pressing SHIFT."
var area3text = "Eliminate the targets and slide again with SHIFT."
var area4text = "Now slide and jump at the same time to get through the gap."
var area5text = "Press C to aim. Aiming zooms in, decreases sensitivity, and decreases recoil, allowing for better accuracy. Shoot the target."
var area6text = "Slide and jump to break the glass and escape."

func _ready() -> void:
	range_enemies = [n1, n2, n3, n4]
	slide_enemies = [slide1, slide2]
	final_enemies = [finalnpc]
	
	player.fade_animation.play_backwards("fade_out")
	player_respawn = player.global_position
	
	dialogue_box.visible = true
	animation.play("slide_in")
	streamDialogue($Player, area0text)
	
func _process(_delta: float) -> void:
	if player.hp <= 0: 
		if player.animation.assigned_animation == "dying":
			if not player.animation.current_animation:
				player.hp = player.max_hp
				player.input_enabled = true
				player.change_collision(true)
				player.global_position = player_respawn
				#player.rotation.y -= player.death_transform
				#player.spring_arm.rotation.y += player.death_transform
				#player.death_transform = 0.0
				player.animation.play("riflecrouchruntostop", 0.5)
		else:
			player.emit_signal("on_ground")
	
	if barrier1 and not enemiesAlive(range_enemies):
		barrier1.free()
	if barrier2 and not enemiesAlive(slide_enemies):
		barrier2.free()
	if finalbarrier and not enemiesAlive(final_enemies):
		finalbarrier.free()

func streamDialogue(body: Node3D, areatext: String) -> void:
	if body.name == "Player":
		current_dialogue_id += 1
		var this_id = current_dialogue_id
		dialogue_text.text = ""
		
		for letter in areatext:
			if current_dialogue_id != this_id: return
			timer.start(text_speed)
			dialogue_text.text += letter
			await timer.timeout
			
func enemiesAlive(enemies: Array) -> int:
	var count: int = 0
	for enemy in enemies:
		if is_instance_valid(enemy):
			if enemy.alive:
				count += 1
	return count
			
func _on_area_1_body_entered(body: Node3D) -> void:
	streamDialogue(body, area1text)

func _on_area_2_body_entered(body: Node3D) -> void:
	streamDialogue(body, area2text)

func _on_area_3_body_entered(body: Node3D) -> void:
	streamDialogue(body, area3text)

func _on_area_4_body_entered(body: Node3D) -> void:
	streamDialogue(body, area4text)

func _on_area_5_body_entered(body: Node3D) -> void:
	streamDialogue(body, area5text)

func _on_area_6_body_entered(body: Node3D) -> void:
	streamDialogue(body, area6text)
