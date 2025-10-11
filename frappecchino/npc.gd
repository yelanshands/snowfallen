extends CharacterBody3D

@onready var enemy: Node3D = $enemi
@onready var animation: AnimationPlayer = enemy.get_node("AnimationPlayer")
@onready var skeleton: Skeleton3D = enemy.get_node("Node/Skeleton3D")
@onready var timer: Timer = $Timer
@onready var fov_collision: CollisionShape3D = $fov/CollisionShape3D3

@export var hp : int = 100

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var vel = Vector3(0, 0, 0)
var alive: bool = true
var player: CharacterBody3D
var player_seen: bool = false
var player_in_fov: bool = false
var head_bone: Node

var debug_line_mesh := ImmediateMesh.new()
var debug_line_instance := MeshInstance3D.new()

func _ready() -> void:
	animation.play("FiringRifle0")
	head_bone = skeleton.get_node("mixamorigHeadTop_End")
	
	debug_line_instance.mesh = debug_line_mesh
	add_child(debug_line_instance)

func _process(_delta):	
	if player_seen:
		look_at(player.global_position)
		rotate_y(deg_to_rad(180))
	
	if hp <= 0:
		if not animation.assigned_animation == "Dying0":
			animation.speed_scale = 2.75
			animation.play_section("Dying0", 0.22, 4.4, 0.5)
			alive = false
			timer.start(30.0)
		elif animation.current_animation_position >= 0.6 and animation.speed_scale != 1.0:
			animation.speed_scale = 1.0
		fov_collision.disabled = true
		player_seen = false
		player_in_fov = false
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
	if player_in_fov:
		var space_state = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(head_bone.global_position, player.head_bone.global_position, 1)
		var result = space_state.intersect_ray(query)
		
		if result:
			var collider = result.collider
			#print(collider)
			if collider == player:
				player_seen = true
			else:
				player_seen = false
				
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0
	move_and_slide()
	
func apply_damage(damage_amount):
	hp -= damage_amount

func _on_fov_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		player_in_fov = true
		print(self, "   ", player_in_fov)
		if not player:
			player = body

func _on_fov_body_exited(body: Node3D) -> void:
	if body.name == "Player":
		player_in_fov = false
		print(self, "   ", player_in_fov)
