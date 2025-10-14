extends Node3D
const NPC = preload("uid://ro3nbpeyv3v5")
@onready var enemy_plane1: MeshInstance3D = $Background/Slope1/plane
@onready var enemy_plane2: MeshInstance3D = $Background/Slope2/plane
@onready var enemy_plane3: MeshInstance3D = $Background/Slope3/plane
@onready var enemy_plane4: MeshInstance3D = $Background/Slope4/plane
@onready var enemy_plane5: MeshInstance3D = $Background/Slope5/plane
@onready var enemy_plane6: MeshInstance3D = $Background/Slope6/plane
@onready var player: CharacterBody3D = $Player
@onready var arrow_label: Label = player.get_node("CanvasLayer/MarginContainer/Header/Arrow")
@onready var barriers: StaticBody3D = $Background/Barriers
@onready var slope_mesh_size: Vector3 = $Background/Slope1/MeshInstance3D.mesh.size
@onready var slope1: StaticBody3D = $Background/Slope1
@onready var slope2: StaticBody3D = $Background/Slope2
@onready var slope3: StaticBody3D = $Background/Slope3
@onready var slope4: StaticBody3D = $Background/Slope4
@onready var slope5: StaticBody3D = $Background/Slope5
@onready var slope6: StaticBody3D = $Background/Slope6
@onready var fade_animation: AnimationPlayer = $CanvasLayer/AnimationPlayer

var enemies: Array = [[], [], [], [], [], []]
var enemy_planes: Array = []
var slopes: Array = []
var current_zloc: float
var dropping: bool = true

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	enemy_planes = [enemy_plane1, enemy_plane2, enemy_plane3, enemy_plane4, enemy_plane5, enemy_plane6]
	for index in range(1, enemy_planes.size()):
		spawn_wave(index)
	
	slopes = [slope1, slope2, slope3, slope4, slope5]

	current_zloc = slope_mesh_size.x*3
	
	fade_animation.play_backwards("fade_out")
	player.velocity = Vector3.ZERO
	player.rotation.y = 0.0
	player.input_enabled = false
	
	Input.action_press("sprint")
	Input.action_release("sprint")
	
func _process(_delta: float) -> void:
	var player_pos = player.global_position
	barriers.global_position.y = player_pos.y
	barriers.global_position.z = player_pos.z
	
	if player.hp <= 0: 
		if player.animation.assigned_animation == "dying":
			if not player.animation.current_animation:
				queue_free()
				get_tree().change_scene_to_file("res://home.tscn")
		else:
			player.emit_signal("on_ground")
	else:
		if player_pos.z > current_zloc:
			var last_slope_pos = slopes[-1].position
			var slope_index = int(str(slopes[0].name)[5])
			
			slopes[0].position.z = last_slope_pos.z + slope_mesh_size.x*2
			slopes[0].position.y = last_slope_pos.y - slope_mesh_size.y*2
			
			enemies[slope_index].clear()
			slopes.append(slopes.pop_at(0))
			current_zloc += slope_mesh_size.x*2
			print(slope_index)
			print(slopes[-1].name)
			spawn_wave(slope_index)
			
		if dropping:
			player.crosshair.set_size(Vector2(lerp(player.crosshair.size.x, player.crosshair_size, 0.15), lerp(player.crosshair.size.y, player.crosshair_size, 0.15)))
			player.crosshair.position = Vector2(player.crosshair_cont.size.x/2.0-(player.crosshair.size.x/2.0), player.crosshair_cont.size.y/2.0-(player.crosshair.size.y/2.0))
			if player.position.y < 100.0:
				dropping = false
				player.input_enabled = true

func spawn_wave(index: int) -> void:
	if player.hp > 0:
		for x in randi_range(1, 6):
			var enemy = NPC.instantiate()
			enemy.enemy_type = "snowshooter"
			enemy.position = get_random_point_on_sloped_plane(enemy_planes[index])
			enemy.rotation.y = randf_range(-150.0, 150.0)
			enemy.plane_index = index
			add_child(enemy)
			
			enemies[index].append(enemy)
			enemy.tree_exited.connect(enemy_died.bind(enemy))
		
		var amount: int = enemies.size()
		arrow_label.text = ((" ".repeat(int(6 * (amount - 3.5)))) if amount > 3 else "")  + "⮝" + ((" ".repeat(int(6 * (3.5 - amount)))) if amount <= 3 else "")

func enemy_died(enemy: Node) -> void:
	if player.hp > 0:
		enemies[enemy.plane_index].erase(enemy)
		#if not enemies:
			#spawn_wave(enemy.plane_index)
		var amount: int = enemies.size()
		arrow_label.text = ((" ".repeat(int(6 * (amount - 3.5)))) if amount > 3 else "")  + "⮝" + ((" ".repeat(int(6 * (3.5 - amount)))) if amount <= 3 else "")

func get_random_point_on_sloped_plane(plane: MeshInstance3D) -> Vector3:
	var size_x = plane.mesh.size.x
	var size_z = plane.mesh.size.y

	var local_x = randf_range(-size_x/2.0, size_x/2.0)
	var local_z = randf_range(-size_z/2.0, size_z/2.0)
	
	var world_pos = plane.global_transform * Vector3(local_x, 0, local_z)
	
	var y = get_y_on_plane(plane, world_pos.x, world_pos.z)
	world_pos.y = y
	
	return world_pos

func get_y_on_plane(plane: MeshInstance3D, x: float, z: float) -> float:
	var n = plane.global_transform.basis.y.normalized()
	var p0 = plane.global_transform.origin
	
	if abs(n.y) < 0.0001:
		return p0.y
	
	return ((n.x * (p0.x - x)) + (n.z * (p0.z - z)) + (n.y * p0.y)) / n.y
