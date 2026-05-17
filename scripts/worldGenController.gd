extends Node

@export var roomsInWorld : int = 3
@export var rooms : int = 64
@export var seedInt : int = 1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	generateWorld()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func generateWorld() -> void:
	var roomArray = []
	for x in rooms:
		roomArray.append(get_hash_random(x)*rooms)
		print_debug(str(roomArray[x]) + "\n")
		
func get_hash_random(x: int) -> float:
	var s = sin(float(x) * 12.9898 + float(seedInt) * 78.233) * 43758.5453123
	return abs(s - floor(s))
