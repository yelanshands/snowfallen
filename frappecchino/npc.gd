extends CharacterBody3D

@onready var enemy: Node3D = $enemi
@onready var animation: AnimationPlayer = enemy.get_node("AnimationPlayer")
@onready var skeleton: Skeleton3D = enemy.get_node("Node/Skeleton3D")
@onready var timer: Timer = $Timer

@export var hp : int = 100

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var vel = Vector3(0, 0, 0)
var alive: bool = true

func _ready() -> void:
	animation.play("FiringRifle0")

func _process(_delta):
	if hp <= 0:
		if not animation.assigned_animation == "Dying0":
			animation.speed_scale = 2.75
			animation.play_section("Dying0", 0.22, 4.4, 0.5)
			alive = false
			timer.start(30.0)
		elif animation.current_animation_position >= 0.6 and animation.speed_scale != 1.0:
			animation.speed_scale = 1.0
		for child in skeleton.get_children():
			for grandchild in child.get_children():
				if not grandchild is StaticBody3D:
					break
				else:
					for greatgrandchild in grandchild.get_children():
						if greatgrandchild is CollisionShape3D:
							greatgrandchild.disabled = true
		if timer.is_stopped():
			queue_free()
		
func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0
	move_and_slide()
	
func apply_damage(damage_amount):
	hp -= damage_amount
