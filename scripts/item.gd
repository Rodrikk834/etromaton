extends Area2D

var id_item: int = 4

#func pickup(player) -> void:
#	player.unlock_shooting()
#	queue_free()

func pickup(player) -> void:
	match id_item:
		0: print("Picked up Flashlight")
		1: print("Picked up Screwdriver")
		2: print("Picked up Tweezers")
		3: print("Picked up Keys")
		4: 
			print("Picked up Taser")
			player.unlock_shooting()
		5: print("Picked up Instructions I")
		6: print("Picked up Instructions II")
		7: print("Picked up Note 1w")
		8: print("Picked up Note 2")
		9: print("Picked up Note 3")
		_: print("Unknown item: ", id_item)
	#PlayerInventory.add_item(id_item)
	PlayerInventory.spawmer.create_sprite(id_item)
	queue_free()

# función para asignarle diccionario desde la creación :D
func set_id(id: int) -> void:
	id_item = id
