extends Node

@export var ItemsSprites: Array[Texture2D]

func create_item_by_id(id: int) -> Item:
	
	var items_data = {
		0: {
			"name": "Flashlight",
			"desc": "pos nomas"
		},
		
		1: {
			"name": "Screwdriver",
			"desc": "pos nomas"
		},
		
		2: {
			"name": "Tweezers",
			"desc": "pos nomas"
		},
		
		3: {
			"name": "Keys",
			"desc": "pos nomas"
		},
		
		4: {
			"name": "Taser",
			"desc": "pos nomas"
		},
		
		5: {
			"name": "Instructions1",
			"desc": "pos nomas"
		},
		
		6: {
			"name": "Instructions2",
			"desc": "pos nomas"
		},
		
		7: {
			"name": "Notes",
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
