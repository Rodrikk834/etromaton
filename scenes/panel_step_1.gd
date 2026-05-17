extends Node2D

@export var torn: Texture2D
@export var tapa: Texture2D

var tornillos: Array[Sprite2D] #sprites de los tornillos
var vueltas: Array[int] #cantidad de vueltas que ha dado cada tornillo
var limite_vueltas: int = 3

func _ready() -> void:
	var i: int = 0
	while i < 4:
		tornillos.push_back(torn)
		vueltas.push_back(0)
		
