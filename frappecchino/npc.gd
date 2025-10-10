extends CharacterBody3D

@onready var enemi: Node3D = $enemi
@onready var animation: AnimationPlayer = enemi.get_node("AnimationPlayer")

@export var hp : int = 100
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var vel = Vector3(0, 0, 0)

func _ready() -> void:
	animation.play("FiringRifle0")
	
func _process(_delta):
	if hp <= 0:
		queue_free() 
		
func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0
	move_and_slide()
	
func apply_damage(damage_amount):
	hp -= damage_amount
