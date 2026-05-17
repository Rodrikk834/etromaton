extends State
class_name RobotIdle

@export_category("Configuración de Patrulla")
@export var radius := 500.0
@export var moveSpeed := 100.0
@export var waitDuration := 2.0
@export var detectionRadius := 150.0
@export var animated_sprite : AnimatedSprite2D

@export_category("Referencias")
@export var enemy: CharacterBody2D
@export var NavigationAgent: NavigationAgent2D

# Referencia al jugador (se busca por grupo)
var player: CharacterBody2D

enum Phase { MOVING, WAITING }
var phase = Phase.MOVING
var wait_timer := 0.0

func _ready():
	# Buscamos al jugador en el grupo "player"
	player = get_tree().get_first_node_in_group("player")
	
	if player == null:
		push_warning("RobotIdle: No se encontró al jugador en el grupo 'player'.")
	
	# Si no asignaste el agente en el inspector, intentamos buscarlo en el hijo
	if NavigationAgent == null and enemy != null:
		NavigationAgent = enemy.get_node_or_null("NavigationAgent2D")

func Enter():
	# 1. PEQUEÑA ESPERA INICIAL
	# Le damos un frame de física para que el agente se vincule internamente 
	# al mapa de navegación por defecto de Godot.
	animated_sprite.play("idle")
	if not NavigationAgent.is_node_ready():
		await NavigationAgent.ready
	await get_tree().physics_frame

	# 2. OBTENER EL RID DEL MAPA
	var map_rid = NavigationAgent.get_navigation_map()
	
	# 3. VALIDACIÓN DE SEGURIDAD
	# Verificamos que el RID no sea nulo antes de preguntarle al servidor.
	if map_rid.is_valid():
		# Si el servidor aún no ha procesado la primera iteración (ID 0), esperamos.
		if NavigationServer2D.map_get_iteration_id(map_rid) == 0:
			await NavigationServer2D.map_changed
			await get_tree().physics_frame
	else:
		# Si llegamos aquí y el RID sigue siendo inválido, esperamos un poco más.
		push_warning("RobotIdle: El Agente aún no tiene un mapa asignado. Reintentando en el siguiente frame...")
		await get_tree().physics_frame
		Enter() # Reintento recursivo controlado
		return
	
	pick_new_target()

func pick_new_target():
	if NavigationAgent == null: return
	
	var map = NavigationAgent.get_navigation_map()
	
	# Validación de seguridad: si por alguna razón extraña el mapa sigue inválido, 
	# esperamos en lugar de crashear el servidor de C++
	if not map.is_valid() or NavigationServer2D.map_get_iteration_id(map) == 0:
		phase = Phase.WAITING
		wait_timer = 0.0
		return

	var snapped: Vector2
	var found := false

	# Intentamos buscar un punto válido en el NavMesh hasta 10 veces
	for i in range(10):
		var random_point = random_in_radius(enemy.global_position)
		
		# Le pedimos al servidor el punto caminable más cercano a nuestra posición aleatoria
		snapped = NavigationServer2D.map_get_closest_point(map, random_point)
		
		# Si el punto encontrado está cerca del punto deseado (no atravesó muros), es válido
		if random_point.distance_to(snapped) <= 50.0:
			found = true
			break

	if found:
		NavigationAgent.target_position = snapped
		phase = Phase.MOVING
	else:
		# Si no encontró nada, espera un tiempo y vuelve a intentar
		phase = Phase.WAITING
		wait_timer = 0.0

func random_in_radius(origin: Vector2) -> Vector2:
	return Vector2(
		randf_range(origin.x - radius, origin.x + radius),
		randf_range(origin.y - radius, origin.y + radius)
	)

func Physics_Update(_delta: float):
	if NavigationAgent == null: return
	
	# Detección del jugador para transición de estado
	if player != null:
		if enemy.global_position.distance_to(player.global_position) <= detectionRadius:
			Transitioned.emit(self, "RobotFollow")
			return
	
	if phase == Phase.MOVING:
		# Si llegamos al destino aleatorio, empezamos a esperar
		if NavigationAgent.is_target_reached():
			phase = Phase.WAITING
			wait_timer = 0.0
			enemy.velocity = Vector2.ZERO # Detenemos al robot
		else:
			# Lógica de movimiento suave hacia el siguiente punto del camino
			var next_pos = NavigationAgent.get_next_path_position()
			var direction = (next_pos - enemy.global_position).normalized()
			enemy.velocity = direction * moveSpeed
			enemy.move_and_slide()

	elif phase == Phase.WAITING:
		wait_timer += _delta
		if wait_timer >= waitDuration:
			pick_new_target()
