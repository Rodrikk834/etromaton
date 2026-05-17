extends Node2D

@onready var spawmer = $CanvasLayer/Spawmer

func add_item(item_ID: int) -> void:
	spawmer.create_sprite(item_ID)
