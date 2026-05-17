extends Node

@export var roomsInWorld : int = 3
@export var rooms : int = 64
@export var seedInt : int = 123456
@export var noise : FastNoiseLite = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	generateWorld()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func generateWorld() -> void:
	noise.seed = seedInt
	var roomArray = []
	for x in rooms:
		roomArray.append(noise.get_noise_1d(x*91))
		print_debug(str((roomArray[x] + 1)/2) + "\n")
