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

var range_enemies: Array
var slide_enemies: Array
var final_enemies: Array

func _ready() -> void:
	range_enemies = [n1, n2, n3, n4]
	slide_enemies = [slide1, slide2]
	final_enemies = [finalnpc]

func _process(_delta: float) -> void:
	if range_enemies.all(func(e): return not is_instance_valid(e)) and barrier1:
		barrier1.free()
	if slide_enemies.all(func(e): return not is_instance_valid(e)) and barrier2:
		barrier2.free()
	if final_enemies.all(func(e): return not is_instance_valid(e)) and finalbarrier:
		finalbarrier.free()
