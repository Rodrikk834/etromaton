extends Node2D

@onready var spawmer = $CanvasLayer/Spawmer

func add_item(item_ID: int) -> void:
	spawmer.create_sprite(item_ID)


func hide_canvas() -> void:
	$CanvasLayer.visible = false
	
func show_canvas() -> void:
	$CanvasLayer.visible = true
	
var visible_inventory: bool
func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_I:
			if !visible_inventory: show_canvas()
			else: hide_canvas()
			visible_inventory = !visible_inventory

# En el script de Inventories o en cada sub-escena
func _ready() -> void:
	hide_canvas()
	visible_inventory = false
