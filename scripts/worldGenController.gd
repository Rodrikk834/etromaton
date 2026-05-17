extends Node
class_name WorldGenerator

@export_category("Configuración de Generación")
@export var semilla_inicial : int = 2
@export var limite_cuartos : int = 100

@export_category("Catálogo de Escenas")
@export var escenas_cuartos : Array[PackedScene] = []

@export_category("Configuración Visual")
@export var id_source_muros : int = 1
@export var muro_arriba : Vector2i = Vector2i(0, 1)
@export var muro_abajo : Vector2i = Vector2i(1, 0)
@export var muro_izquierda : Vector2i = Vector2i(1, 1)
@export var muro_derecha : Vector2i = Vector2i(0, 0)
@export var id_source_piso : int = 1
@export var atlas_piso_sellado : Vector2i = Vector2i(0, 4)

@onready var mapa_piso = $floors
@onready var mapa_muros = $walls

var rng := RandomNumberGenerator.new()
var grid : Dictionary = {}
var base_de_datos_cuartos : Array = []
var puertas_pendientes : Array = []
var cuartos_generados : int = 0

# Clase de Godot para caminos inteligentes
var astar = AStar2D.new()

func _ready():
	rng.seed = semilla_inicial
	preparar_catalogo()
	generar_mapa()
	# Aquí podrías llamar a una función para conectar puertas lejanas con A*
	# Por ahora, sellamos las que sobran.
	_sellar_puertas_sobrantes()
	dibujar_mapa_final()

func preparar_catalogo():
	for id in range(escenas_cuartos.size()):
		var cuarto_temp = escenas_cuartos[id].instantiate()
		var datos_del_cuarto = cuarto_temp.exportar_datos_matematicos(id)
		base_de_datos_cuartos.append(datos_del_cuarto)
		cuarto_temp.queue_free()

func generar_mapa():
	_registrar_cuarto_en_grid(0, Vector2.ZERO)
	
	while cuartos_generados < limite_cuartos and puertas_pendientes.size() > 0:
		var indice_puerta = rng.randi_range(0, puertas_pendientes.size() - 1)
		var puerta_actual = puertas_pendientes[indice_puerta]
		puertas_pendientes.remove_at(indice_puerta)
		
		var direccion_buscada = puerta_actual.direccion * -1
		var cuartos_compatibles = []
		
		for cuarto in base_de_datos_cuartos:
			if direccion_buscada in cuarto.direcciones_soportadas:
				cuartos_compatibles.append(cuarto)
				
		if cuartos_compatibles.size() > 0:
			var cuarto_elegido = cuartos_compatibles[rng.randi() % cuartos_compatibles.size()]
			var puerta_compatible = null
			
			for p in cuarto_elegido.puertas:
				if p.direccion == direccion_buscada:
					puerta_compatible = p
					break
					
			if puerta_compatible != null:
				var pos_global_nuevo_cuarto = puerta_actual.posicion_global - puerta_compatible.posicion_local
				var hay_colision = false
				
				for tile in cuarto_elegido.tiles_ocupados:
					var pos_test = pos_global_nuevo_cuarto + tile.posicion_local
					var diff = (pos_test - puerta_actual.posicion_global).abs()
					if diff.x <= 1 and diff.y <= 1: continue
						
					if grid.has(pos_test) and grid[pos_test].has(tile.nombre_capa):
						hay_colision = true
						break
				
				if not hay_colision:
					_registrar_cuarto_en_grid(cuarto_elegido.id, pos_global_nuevo_cuarto, puerta_compatible.posicion_local)

func _registrar_cuarto_en_grid(id_catalogo: int, posicion_global_cuarto: Vector2, pos_puerta_ignorada: Vector2 = Vector2(-999, -999)):
	var datos = base_de_datos_cuartos[id_catalogo]
	
	for tile in datos.tiles_ocupados:
		var celda_global = posicion_global_cuarto + tile.posicion_local
		if not grid.has(celda_global):
			grid[celda_global] = {}
		
		grid[celda_global][tile.nombre_capa] = {
			"source_id": tile.source_id,
			"atlas_coords": tile.atlas_coords,
			"alternative_tile": tile.alternative_tile
		}
		
		# REGISTRO PARA A*: Si es piso, lo añadimos como punto navegable
		if tile.nombre_capa == "floors":
			var id_punto = _get_id_for_pos(celda_global)
			if not astar.has_point(id_punto):
				astar.add_point(id_punto, celda_global)
				_conectar_con_vecinos_astar(celda_global, id_punto)

	for puerta_local in datos.puertas:
		if puerta_local.posicion_local == pos_puerta_ignorada: continue
		puertas_pendientes.append({
			"posicion_global": posicion_global_cuarto + puerta_local.posicion_local,
			"direccion": puerta_local.direccion
		})
	cuartos_generados += 1

# --- FUNCIONES AUXILIARES PARA A* ---

func _get_id_for_pos(pos: Vector2) -> int:
	# Genera un ID único basado en las coordenadas (Cantor pairing o simple hash)
	return int(pos.x) + int(pos.y) * 100000 

func _conectar_con_vecinos_astar(pos: Vector2, id: int):
	var direcciones = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]
	for dir in direcciones:
		var pos_vecina = pos + dir
		var id_vecino = _get_id_for_pos(pos_vecina)
		if astar.has_point(id_vecino):
			astar.connect_points(id, id_vecino)

func crear_pasillo_astar(inicio: Vector2, fin: Vector2):
	# Esta función permitiría trazar un camino de piso entre dos puntos
	# Si los puntos no están en el grafo, los añadimos temporalmente
	var id_a = _get_id_for_pos(inicio)
	var id_b = _get_id_for_pos(fin)
	
	if astar.has_point(id_a) and astar.has_point(id_b):
		var camino = astar.get_point_path(id_a, id_b)
		for punto in camino:
			# Pintamos el pasillo en el grid
			if not grid.has(punto):
				grid[punto] = {"floors": {
					"source_id": id_source_piso,
					"atlas_coords": atlas_piso_sellado,
					"alternative_tile": 0
				}}

# --- SELLADO Y DIBUJO ---

func _sellar_puertas_sobrantes():
	for puerta in puertas_pendientes:
		var atlas_muro : Vector2i
		var perp : Vector2
		var offset_correccion := Vector2.ZERO
		
		match puerta.direccion:
			Vector2.UP:
				atlas_muro = muro_arriba
				perp = Vector2.RIGHT
				offset_correccion = Vector2(0, 1)
			Vector2.DOWN:
				atlas_muro = muro_abajo
				perp = Vector2.RIGHT
			Vector2.LEFT:
				atlas_muro = muro_izquierda
				perp = Vector2.DOWN
				offset_correccion = Vector2(1, 0)
			Vector2.RIGHT:
				atlas_muro = muro_derecha
				perp = Vector2.DOWN
		
		for i in range(-1, 2):
			var pos_relleno = puerta.posicion_global + (perp * i) + offset_correccion
			if not grid.has(pos_relleno): grid[pos_relleno] = {}
			if not grid[pos_relleno].has("floors"):
				grid[pos_relleno]["floors"] = {
					"source_id": id_source_piso, "atlas_coords": atlas_piso_sellado, "alternative_tile": 0
				}
			grid[pos_relleno]["walls"] = {
				"source_id": id_source_muros, "atlas_coords": atlas_muro, "alternative_tile": 0
			}
	puertas_pendientes.clear()

func dibujar_mapa_final():
	for celda_global in grid:
		var celda_vector_i = Vector2i(celda_global.x, celda_global.y)
		var capas = grid[celda_global]
		if capas.has("floors"):
			var d = capas["floors"]
			mapa_piso.set_cell(celda_vector_i, d.source_id, d.atlas_coords, d.alternative_tile)
		if capas.has("walls"):
			var d = capas["walls"]
			mapa_muros.set_cell(celda_vector_i, d.source_id, d.atlas_coords, d.alternative_tile)
