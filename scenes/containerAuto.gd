extends Node2D

@onready var spawmer = $CanvasLayer/SpawmerContainer

func add_item(item_ID: int) -> void:
	spawmer.create_sprite(item_ID)


func hide_canvas() -> void:
	$CanvasLayer.visible = false
	
func show_canvas() -> void:
	$CanvasLayer.visible = true

# En el script de Inventories o en cada sub-escena
func _ready() -> void:
	hide_canvas()
