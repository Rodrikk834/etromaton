extends Node2D

@export var cables: Array[TextureRect]
@export var cables_collisions: Array[CollisionPolygon2D]
@export var back: TextureRect
@export var game_manager: Node2D

var actual_index: int = 0
var ordered_colors: Array[int] = [0, 1, 2, 3]

func _ready() -> void:
	#ordered_colors.shuffle()
	pass

func check_cable(index: int) -> void:
	# si no es el correcto, la velocidad del robot se retoma
	if index >= 0 && index <= 2: delete_cable(2, 0) # rojo
	elif index >= 4 && index <= 10: delete_cable(3, 1) # verde
	elif index >= 11 && index <= 19: delete_cable(1, 2) # azul
	elif index >= 20 && index <= 25: delete_cable(0, 3) # amarillo
	pass

# está bien la lógica de los números, la que elige los cables a hacer invisibles no
func delete_cable(index_cable: int, index_coll: int) -> void:
	if checkOrder(index_cable):
		cables_collisions[index_coll].queue_free()
		cables[index_cable].visible = false
	

func checkOrder(cable: int) -> bool:
	if ordered_colors[actual_index] == cable:
		actual_index += 1
		if actual_index == 4:
			game_manager.advance()
		return true
	return false
