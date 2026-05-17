extends Node2D

@export var boxSprite: Texture2D
@export var item_creator: Node
@export var item_description: Node

const rows: int = 3
const columns: int = 4
const cellSize: Vector2 = Vector2(170, 170) # espacio entre celdas
const origin: Vector2 = Vector2(150, 100) # esquina superior izquierda de la cuadrícula
var index: int = 0

var itemsInventory = {} #hash map to find items

func get_cell_position(idx: int) -> Vector2:
	var col := idx % columns
	var row := idx / columns
	return origin + Vector2(col * cellSize.x, row * cellSize.y)

func create_sprite(item_type: int) -> void:
	var pos := get_cell_position(index)
	index += 1

	# 1. crear la box
	var box := Sprite2D.new()
	box.texture = boxSprite
	box.position = pos
	box.scale = Vector2(0.1, 0.1)
	add_child(box)

	# 2. obtener el Item
	var item = item_creator.create_item_by_id(item_type)
	itemsInventory[item_type] = item

	# 3. poner el botoncito
	var btn := TextureButton.new()
	btn.texture_normal = item.item_sprite
	btn.position = pos
	btn.z_index = 1
	btn.scale = Vector2(0.1, 0.1)
	add_child(btn)
	
	# Conectar el click
	btn.pressed.connect(func():
		item_description.enter_description(item)
		quit_inventory_spawmer()
	)
	
	
func quit_inventory_spawmer() -> void:
	visible = false
	
	
func enter_inventory_spawmer() -> void:
	visible = true
	
	
func is_on_inventory(item_type: int) -> bool:
	if itemsInventory.has(item_type):
		return true
	return false
	
	
#Para llamarlas desde el player:
#@export var inventory: Node2D
#func _ready() -> void:
	#inventory.enter_inventory()

func _ready() -> void:
	create_sprite(1)
	create_sprite(2)
	create_sprite(3)
	create_sprite(4)
	create_sprite(5)
