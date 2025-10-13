extends RayCast3D

@onready var remote_transform := RemoteTransform3D.new()
@onready var player: CharacterBody3D = get_parent().get_parent().get_parent().get_parent()
@onready var animation: AnimationPlayer = $AnimationPlayer
@onready var hitcrosshair_cont: Control = player.get_node("Crosshair/HitContainer")

@export var speed: float = 1400.0

var damage_amount := 25.0
var crosshair_size: float
var fov: float
var enemy_dead: bool = false
var hit: bool = false

signal crosshair_done

func _ready() -> void:
	crosshair_size = player.crosshair_size
	fov = player.fov
	set_process(false)
	animation.play("fade_in")
	
func _process(delta: float) -> void:
	hitcrosshair_cont.scale = Vector2(lerp(hitcrosshair_cont.scale.x, 0.8, 30.0*delta), lerp(hitcrosshair_cont.scale.y, 0.8, 30.0*delta))
	
	if hitcrosshair_cont.scale.x > 0.77:
		hitcrosshair_cont.scale = Vector2(0.0, 0.0)
		set_process(false)
		emit_signal("crosshair_done")
			
func _physics_process(delta: float) -> void:
	position -= global_basis * Vector3.BACK * speed * delta
	target_position = -(Vector3.BACK * speed * delta)
	force_raycast_update()
	var collided = get_collider()
	var current = collided
	if is_colliding():
		global_position = get_collision_point()
		set_physics_process(false)
		if collided.name == "head":
			damage_amount = 100
		elif collided.name == "body":
			damage_amount = 25
		elif collided.name == "leg":
			damage_amount = 20
		while current:
			if current.is_in_group("attackable"):
				if current.has_method("apply_damage"):
					hitcrosshair_cont.scale = Vector2(0.0, 0.0)
					set_process(true)
					player.update_score(damage_amount if current.hp >= damage_amount else current.hp)
					if current.hp <= damage_amount:
						enemy_dead = true
					current.apply_damage(damage_amount)
				break
			current = current.get_parent()
		collided.add_child(remote_transform)
		remote_transform.global_transform = global_transform
		remote_transform.remote_path = remote_transform.get_path_to(self)
		remote_transform.tree_exited.connect(cleanup)
		
func cleanup() -> void:
	if enemy_dead:
		visible = false
		await crosshair_done
	hitcrosshair_cont.scale = Vector2(0.0, 0.0)
	queue_free()
