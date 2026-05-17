extends Area2D

@export var step: Node2D

func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		print("click en shape:", shape_idx)
		step.check_cable(shape_idx)
