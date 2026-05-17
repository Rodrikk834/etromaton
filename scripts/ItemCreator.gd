extends Node

@export var ItemsSprites: Array[Texture2D]

func create_item_by_id(id: int) -> Item:
	
	var items_data = {
		0: {
			"name": "Flashlight",
			"desc": "Just a flashlight, what you need to barely see those who see you clearly."
		},
		1: {
			"name": "Screwdriver",
			"desc": "Worn out, but still useful for loose panels."
		},
		2: {
			"name": "Tweezers",
			"desc": "Useful to cut thick things, but not that thick"
		},
		3: {
			"name": "Keys",
			"desc": "Could there be something locked up in there?"
		},
		4: {
			"name": "Taser",
			"desc": "It takes a long time to recharge, but it's useful."
		},
		5: {
			"name": "Instructions",
			"desc": "A dónde mirar? Al panel en la espalda del robot"
		},
		6: {
			"name": "Instructions II",
			"desc": "Orden de cable a cortar: amarillo, verde"
		},
		7: {
			"name": "Notes",
			"desc": "Nota 1 ns ahora la escribo"
		},
		8: {
			"name": "Notes",
			"desc": "Nota 2 ns ahora la escribo"
		},
		9: {
			"name": "Notes",
			"desc": "Nota 3 ns ahora la escribo"
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
