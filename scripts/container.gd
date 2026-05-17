extends Node2D
class_name Containers

var rng := RandomNumberGenerator.new()
@export var items_dentro : Array[Item]

func _ready():
	await get_tree().process_frame
	var identificador_unico = str(GlobalController.world_seed) + str(global_position.x) + str(global_position.y)
	rng.seed = identificador_unico.hash()
	_generar_contenido()

func _generar_contenido():
	for x in rng.randi_range(0, 4):
		var tipo_item = rng.randi_range(0, GlobalController.items_normales_array.size() - 1)
		var item_temp = GlobalController.items_normales_array[tipo_item]
		items_dentro.append(item_temp)
	

func pickup(player):
	player.unlock_shooting()
	queue_free()
