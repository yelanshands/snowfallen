extends CharacterBody3D

@onready var enemy: Node3D = $enemi
@onready var animation: AnimationPlayer = enemy.get_node("AnimationPlayer")
@onready var skeleton: Skeleton3D = enemy.get_node("Node/Skeleton3D")
@onready var timer: Timer = $Timer
@onready var fov_collision: CollisionShape3D = $fov/CollisionShape3D
@onready var attention_timer: Timer = $AttentionTimer

@export var hp : int = 100
@export var attention_min: float = 8.0
@export var attention_max: float = 15.0

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var vel = Vector3(0, 0, 0)
var alive: bool = true
var player: CharacterBody3D
var player_seen: bool = false
var player_in_fov: bool = false
var head_bone: Node
var idle_rot_y: float
var attention_timer_started: bool = true

func _ready() -> void:
	animation.play("FiringRifle0")
	head_bone = skeleton.get_node("mixamorigHeadTop_End")
	attention_timer.start(randf_range(attention_min, attention_max))
	idle_rot_y = global_rotation.y

func _process(_delta: float) -> void:
	if player_seen:
		var dir = player.global_position - global_position
		var target_rot_y = atan2(dir.x, dir.z)
		global_rotation.y = lerp_angle(global_rotation.y, target_rot_y, 0.15)
	else:
		if attention_timer.is_stopped():
			if global_rotation.y <= idle_rot_y + 0.001 and global_rotation.y >= idle_rot_y - 0.001:
				idle_rot_y = global_rotation.y + randf_range(-PI/9, PI/9)
			else:
				global_rotation.y = lerp_angle(global_rotation.y, idle_rot_y, 0.05)
	
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
		var query = PhysicsRayQueryParameters3D.create(head_bone.global_position, player.head_bone.global_position, (1 << 0) | (1 << 6))
		var result = space_state.intersect_ray(query)
		
		if result:
			var collider = result.collider
			if collider.get_owner().name == "frappie":
				player_seen = true
				attention_timer_started = false
				attention_timer.stop()
			else:
				player_seen = false
				if not attention_timer_started:
					attention_timer_started = true
					attention_timer.start(randf_range(attention_min, attention_max))
				
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
		if not player:
			player = body

func _on_fov_body_exited(body: Node3D) -> void:
	if body.name == "Player":
		player_in_fov = false
