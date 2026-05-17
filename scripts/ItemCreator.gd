extends Node

@export var ItemsSprites: Array[Texture2D]

func create_item_by_id(id: int) -> Item:
	
	var items_data = {
		0: {
			"name": "Linterna",
			"desc": "pos nomas"
		},
		
		1: {
			"name": "Desatornillador",
			"desc": "pos nomas"
		},
		
		2: {
			"name": "Pinzas",
			"desc": "pos nomas"
		},
		
		3: {
			"name": "Instrucciones A",
			"desc": "pos nomas"
		},
		
		4: {
			"name": "Notas",
			"desc": "pos nomas"
		},
		
		5: {
			"name": "Llaves",
			"desc": "pos nomas"
		},
		
		6: {
			"name": "Taser",
			"desc": "pos nomas"
		},
		
		7: {
			"name": "Instrucciones B",
			"desc": "pos nomas"
		}
	}

	var data = items_data[id]
	
	var item = Item.new(
		data["name"],
		data["desc"],
		ItemsSprites[id],
		id
	)
	
	#print("Item created: ", item.item_description, item.item_name)
	
	return item

# 1: linterna
# 2: desatornillador
# 3: pinzas
# 4: instrucciones
# 5: notas
# 6: llaves
# 7: taser
