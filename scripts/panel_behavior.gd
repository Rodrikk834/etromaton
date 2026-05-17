extends Node2D

var actual_step: int = 0
var total_steps: int = 3

func increase_step() -> void:
	actual_step += 1

@export var nodes_steps: Array[Node2D]

func show_step(n_step: int) -> void:
	nodes_steps[n_step].visible = true
	
func hide_step() -> void:
	for i in nodes_steps:
		i.visible = false
		
func advance() -> void:
	hide_step()
	increase_step()
	show_step(actual_step)
		
func _ready() -> void:
	hide_step()
	
	#ahorita borrar esto
	show_step(0)
