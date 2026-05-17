extends Node2D

@export var label_name: Label
@export var item_sprite: TextureRect
@export var items_behavior: Node
@export var take_button: Button
#@export var inventory: Node2D

var current_item: Item = null  # item activo

func _ready() -> void:
	quit_description()
	label_name.add_theme_font_size_override("font_size", 32)
	
	# conectar a botoncito
	take_button.pressed.connect(func():
		take_item()
	)
	
func take_item() -> void:
	#inventory.create_sprite(current_item.item_ID)
	#print("Creado en el inventario: ", current_item.item_name)
	PlayerInventory.add_item(current_item.item_ID)
	quit_description()
	items_behavior.remove_item(current_item.item_ID)	
	

func enter_description(item: Item) -> void:
	current_item = item  # guardar referencia
	label_name.text = item.item_name
	item_sprite.texture = item.item_sprite
	visible = true

func quit_description() -> void:
	items_behavior.enter_inventory_spawmer()
	visible = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		quit_description()

#@export var inventory: Node2D
#func _ready() -> void:
	#inventory.enter_inventory()
