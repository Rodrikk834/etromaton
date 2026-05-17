extends Node2D

var actual_step: int = 0
var total_steps: int = 4

func increase_step() -> void:
	actual_step += 1

@export var nodes_steps: Array[Node2D]

func show_step(n_step: int) -> void:
	nodes_steps[n_step].visible = false
	
func hide_step() -> void:
	for i in nodes_steps:
		i.visible = false
		
func _ready() -> void:
	hide_step()
