extends Node2D
class_name Item

var item_in_inventory: bool = false
var item_name: String
var item_description: String
var item_sprite: Texture2D
var item_ID: int

func _init(i_name: String = "", i_description: String = "", i_sprite: Texture2D = null, i_id: int = 0):
	item_name = i_name
	item_description = i_description
	item_sprite = i_sprite
	item_ID = i_id

# 1: linterna
# 2: desatornillador
# 3: pinzas
# 4: instrucciones / notas
# 5: llaves
