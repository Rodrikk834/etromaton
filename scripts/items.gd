extends Resource
class_name Item

@export var item_name: String
@export var item_description: String
@export var item_sprite: Texture2D
@export var especial: bool

func _init(i_name: String = "", i_description: String = "", i_sprite: Texture2D = null, i_id: int = 0):
	item_name = i_name
	item_description = i_description
	item_sprite = i_sprite

# 1: linterna
# 2: desatornillador
# 3: pinzas
