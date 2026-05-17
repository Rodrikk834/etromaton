extends State
class_name RobotFollow

@export var moveSpeed := 90.0
@export var enemy: CharacterBody2D
@export var NavigationAgent: NavigationAgent2D
@export var path_update_interval := 0.2
@export var detectionRadius := 150.0

# Variable interna, ya no la exportamos al inspector
var player: CharacterBody2D
var path_update_timer := 0.0

func _ready():
	# Buscamos al jugador por su grupo, igual que en el estado Idle
	player = get_tree().get_first_node_in_group("player")
	
	if player == null:
		push_error("RobotFollow: No se encontró al jugador en el grupo 'player'.")

func Enter():
	if player != null:
		NavigationAgent.target_position = player.global_position

func Physics_Update(_delta: float):
	# PROTECCIÓN CONTRA CRASH: Si el jugador ya no existe (ej. murió), volvemos a Idle
	if player == null:
		Transitioned.emit(self, "RobotIdle")
		return
		
	# Si el jugador se aleja demasiado, lo dejamos de seguir
	if enemy.global_position.distance_to(player.global_position) > detectionRadius:
		Transitioned.emit(self, "RobotIdle")
		return
	
	# Actualizamos la ruta cada cierto intervalo para no saturar el procesador
	path_update_timer += _delta
	if path_update_timer >= path_update_interval:
		NavigationAgent.target_position = player.global_position
		path_update_timer = 0.0

	if NavigationAgent.is_navigation_finished():
		return

	# Movimiento usando el NavMesh generado proceduralmente
	var next_pos = NavigationAgent.get_next_path_position()
	var direction = (next_pos - enemy.global_position).normalized()
	enemy.velocity = direction * moveSpeed
	enemy.move_and_slide()
