extends Node3D
const NPC = preload("uid://ro3nbpeyv3v5")
@onready var enemy_plane: MeshInstance3D = $Background/Slope/plane
@onready var arrow_label: Label = $CanvasLayer/MarginContainer/Header/Arrow

var enemies: Array = []

func _ready() -> void:
	spawn_wave()
		
func spawn_wave() -> void:
	for x in randi_range(1, 6):
		var enemy = NPC.instantiate()
		enemy.position = get_random_point_on_sloped_plane(enemy_plane)
		add_child(enemy)
		
		enemies.append(enemy)
		enemy.tree_exited.connect(enemy_died.bind(enemy))
	
	var amount: int = enemies.size()
	arrow_label.text = ((" ".repeat(int(6 * (amount - 3.5)))) if amount > 3 else "")  + "⮝" + ((" ".repeat(int(6 * (3.5 - amount)))) if amount <= 3 else "")


func enemy_died(enemy: Node) -> void:
	enemies.erase(enemy)
	if not enemies:
		spawn_wave()
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
