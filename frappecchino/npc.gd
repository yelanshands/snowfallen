extends Node3D
const silhouette = preload("res://assets/images/frappie_pfp.png")
const frappie = preload("res://assets/images/frappie_silhouette_pfp.png")
@export var hp : int = 100
@export var dialogue = [["???", silhouette, "Make it quick."],
	["Player", frappie, "Of course."],
	["???", silhouette, "Good luck."]
]

var current_dialogue := 0

func _process(_delta):
	if hp <= 0:
		queue_free() 
	if is_in_group("dialogue") and Input.is_action_pressed("interact"):
		pass
		

	
func apply_damage(damage_amount):
	hp -= damage_amount
