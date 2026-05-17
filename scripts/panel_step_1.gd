extends Node2D

@export var torn: Texture2D
@export var back: TextureRect
@export var game_manager: Node2D
var tornillos: Array[Sprite2D] = []
var vueltas: Array[int] = []
var limite_vueltas: int = 5

var posiciones: Array[Vector2] = [Vector2(300, 175), Vector2(860, 175), Vector2(300, 485), Vector2(860, 485)]

func _ready() -> void:
	var i: int = 0
	while i < 4:
		var sprite := Sprite2D.new()
		sprite.texture = torn
		sprite.position = posiciones[i]
		add_child(sprite)
		
		# detectar clicks con areas2d de mierda
		var area := Area2D.new()
		var collision := CollisionShape2D.new()
		var shape := CircleShape2D.new()
		shape.radius = 20
		collision.shape = shape
		area.position = posiciones[i]
		area.add_child(collision)
		add_child(area)
		
		var idx := i
		area.input_event.connect(func(viewport, event, shape_idx):
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				girar_tornillo(idx)
		)
		
		tornillos.push_back(sprite)
		vueltas.push_back(0)
		i += 1

func girar_tornillo(idx: int) -> void:
	if not tornillos[idx].visible:
		return
	
	vueltas[idx] += 1
	
	# animar la mierda de vuelta
	var tween = create_tween()
	tween.tween_property(
		tornillos[idx],
		"rotation",
		tornillos[idx].rotation + TAU,  # TAU = 360 grados
		0.3
	)
	
	if vueltas[idx] >= limite_vueltas:
		tween.tween_callback(func():
			tornillos[idx].visible = false
			print("Tornillo ", idx, " desenroscado")
			verificar_todos()
		)

func verificar_todos() -> void:
	for i in range(4):
		if tornillos[i].visible: return
	print("Todos los tornillos desenroscados")
	# avanzar al siguiente step
	game_manager.advance()
