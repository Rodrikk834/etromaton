extends Node2D

@export var label_description: Label
@export var label_name: Label
@export var item_sprite: TextureRect
@export var items_behavior: Node
@export var exit_button: Button

func enter_description(item: Item) -> void:
	label_name.text = item.item_name
	label_description.text = item.item_description
	item_sprite.texture = item.item_sprite
	print("Item created: ", item.item_description, item.item_name)
	visible = true
	pass
	
func quit_description() -> void:
	items_behavior.enter_inventory_spawmer()
	visible = false

func _ready() -> void:
	quit_description()
	label_name.add_theme_font_size_override("font_size", 32)
	label_description.add_theme_font_size_override("font_size", 20)
	
	exit_button.pressed.connect(func():
		exit_description()
	)
	
func exit_description() -> void:
	quit_description()
	

#func _input(event):
#	if event.is_action_pressed("ui_cancel"):
#		quit_description()
