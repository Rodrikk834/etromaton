extends Area2D

@export var lifetime: float = 0.5

func _ready():
	await get_tree().create_timer(lifetime).timeout
	queue_free()
