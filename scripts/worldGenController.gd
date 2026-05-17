extends Node
class_name WorldGenerator

@export_category("Configuración de Generación")
@export var semilla_inicial : int = 3
@export var limite_cuartos : int = 100

@export_category("Configuración de Pasillos (A*)")
@export var max_length_corridor : int = 5

@export_category("Catálogo de Escenas")
@export var escenas_iniciales : Array[PackedScene] = []
@export var escenas_cuartos : Array[PackedScene] = []

@export var categorias_especiales : Array[Array] = [] 
@export var escenas_relleno : Array[PackedScene] = []

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

var base_de_datos_iniciales : Array = []
var base_de_datos_cuartos : Array = []
var base_de_datos_especiales : Array = [] 
var base_de_datos_relleno : Array = []

var puertas_pendientes : Array = []
var cuartos_generados : int = 0
var contador_instancias : int = 0

func _ready():
	rng.seed = semilla_inicial
	preparar_catalogo()
	
	generar_mapa()
	_inyectar_cuartos_finales()
	_construir_pasillos_astar()
	_sellar_puertas_sobrantes()
	dibujar_mapa_final()

func preparar_catalogo():
	base_de_datos_iniciales = _procesar_array_escenas(escenas_iniciales)
	base_de_datos_cuartos = _procesar_array_escenas(escenas_cuartos)
	base_de_datos_relleno = _procesar_array_escenas(escenas_relleno)
	
	base_de_datos_especiales.clear()
	for categoria in categorias_especiales:
		var categoria_procesada = _procesar_array_escenas(categoria)
		if categoria_procesada.size() > 0:
			base_de_datos_especiales.append(categoria_procesada)

func _procesar_array_escenas(array_escenas: Array) -> Array:
	var base_datos = []
	for i in range(array_escenas.size()):
		var escena = array_escenas[i]
		if escena is PackedScene: 
			var cuarto_temp = escena.instantiate()
			if cuarto_temp.has_method("exportar_datos_matematicos"):
				base_datos.append(cuarto_temp.exportar_datos_matematicos(i))
			cuarto_temp.queue_free()
	return base_datos

func generar_mapa():
	if base_de_datos_iniciales.size() > 0:
		var cuarto_inicio = base_de_datos_iniciales[rng.randi_range(0, base_de_datos_iniciales.size() - 1)]
		_registrar_cuarto_en_grid(cuarto_inicio, Vector2.ZERO)
	else:
		push_error("No has asignado ninguna escena Inicial.")
		return
	
	while cuartos_generados < limite_cuartos and puertas_pendientes.size() > 0:
		var indice_puerta = rng.randi_range(0, puertas_pendientes.size() - 1)
		var puerta_actual = puertas_pendientes[indice_puerta]
		
		if _intentar_pegar_cuarto(puerta_actual, base_de_datos_cuartos):
			puertas_pendientes.remove_at(indice_puerta)

func _inyectar_cuartos_finales():
	puertas_pendientes.sort_custom(func(a, b):
		return a.posicion_global.length_squared() > b.posicion_global.length_squared()
	)
	
	for categoria_variantes in base_de_datos_especiales:
		var variante_elegida = categoria_variantes[rng.randi() % categoria_variantes.size()]
		for i in range(puertas_pendientes.size()):
			var p = puertas_pendientes[i]
			if _intentar_pegar_cuarto(p, [variante_elegida]):
				puertas_pendientes.remove_at(i)
				break 
	
	if base_de_datos_relleno.size() > 0:
		for i in range(puertas_pendientes.size() - 1, -1, -1):
			var p = puertas_pendientes[i]
			var cuarto_bano = base_de_datos_relleno[rng.randi() % base_de_datos_relleno.size()]
			if _intentar_pegar_cuarto(p, [cuarto_bano]):
				puertas_pendientes.remove_at(i)

func _intentar_pegar_cuarto(puerta_destino: Dictionary, catalogo: Array) -> bool:
	var dir_buscada = puerta_destino.direccion * -1
	var compatibles = []
	
	for cuarto in catalogo:
		if dir_buscada in cuarto.direcciones_soportadas:
			compatibles.append(cuarto)
			
	if compatibles.size() > 0:
		var elegido = compatibles[rng.randi() % compatibles.size()]
		var p_local = null
		for p in elegido.puertas:
			if p.direccion == dir_buscada:
				p_local = p
				break
				
		if p_local != null:
			var pos_nueva = puerta_destino.posicion_global - p_local.posicion_local
			if not _checar_colision(elegido, pos_nueva, puerta_destino.posicion_global):
				_registrar_cuarto_en_grid(elegido, pos_nueva, p_local.posicion_local)
				return true
	return false

func _checar_colision(cuarto: Dictionary, pos_global_cuarto: Vector2, pos_puerta_actual: Vector2) -> bool:
	for tile in cuarto.tiles_ocupados:
		var pos_test = pos_global_cuarto + tile.posicion_local
		var diff = (pos_test - pos_puerta_actual).abs()
		if diff.x <= 1 and diff.y <= 1: continue 
			
		if grid.has(pos_test) and grid[pos_test].has(tile.nombre_capa):
			return true
	return false

func _registrar_cuarto_en_grid(datos_cuarto: Dictionary, posicion_global_cuarto: Vector2, pos_puerta_ignorada: Vector2 = Vector2(-999, -999)):
	contador_instancias += 1 
	
	for tile in datos_cuarto.tiles_ocupados:
		var celda_global = posicion_global_cuarto + tile.posicion_local
		if not grid.has(celda_global): grid[celda_global] = {}
		
		grid[celda_global][tile.nombre_capa] = {
			"source_id": tile.source_id,
			"atlas_coords": tile.atlas_coords,
			"alternative_tile": tile.alternative_tile
		}

	for puerta_local in datos_cuarto.puertas:
		if puerta_local.posicion_local == pos_puerta_ignorada: continue
		puertas_pendientes.append({
			"posicion_global": posicion_global_cuarto + puerta_local.posicion_local,
			"direccion": puerta_local.direccion,
			"id_cuarto": contador_instancias 
		})
	cuartos_generados += 1

func _construir_pasillos_astar():
	if puertas_pendientes.size() < 2: return

	var astar_grid = AStarGrid2D.new()
	astar_grid.cell_size = Vector2i(1, 1)
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	
	var rect_min = Vector2i(100000, 100000)
	var rect_max = Vector2i(-100000, -100000)
	for pos in grid:
		rect_min.x = min(rect_min.x, int(pos.x))
		rect_min.y = min(rect_min.y, int(pos.y))
		rect_max.x = max(rect_max.x, int(pos.x))
		rect_max.y = max(rect_max.y, int(pos.y))
		
	var padding = 20
	astar_grid.region = Rect2i(rect_min - Vector2i(padding, padding), (rect_max - rect_min) + Vector2i(padding * 2, padding * 2))
	astar_grid.update()
	
	for pos in grid:
		astar_grid.set_point_solid(Vector2i(pos.x, pos.y), true)
		
	var puertas_aisladas = []
	var celdas_pasillo = []
	
	while puertas_pendientes.size() >= 2:
		var pA = puertas_pendientes.pop_front()
		
		var pB_index = -1
		var min_dist = INF
		
		for i in range(puertas_pendientes.size()):
			if pA.id_cuarto == puertas_pendientes[i].id_cuarto:
				continue
				
			var dist = pA.posicion_global.distance_squared_to(puertas_pendientes[i].posicion_global)
			if dist < min_dist:
				min_dist = dist
				pB_index = i
				
		if pB_index == -1:
			puertas_aisladas.append(pA)
			continue
			
		var pB = puertas_pendientes.pop_at(pB_index)
		
		var inicio = Vector2i(pA.posicion_global)
		var fin = Vector2i(pB.posicion_global)
		var inicio_fuera = Vector2i(pA.posicion_global + pA.direccion)
		var fin_fuera = Vector2i(pB.posicion_global + pB.direccion)
		
		astar_grid.set_point_solid(inicio, false)
		astar_grid.set_point_solid(fin, false)
		astar_grid.set_point_solid(inicio_fuera, false)
		astar_grid.set_point_solid(fin_fuera, false)
		
		var path = astar_grid.get_id_path(inicio_fuera, fin_fuera)
		
		# --- NUEVO CONSTRAINT: Límite de Longitud ---
		# Si no hay camino O la ruta es mayor a la longitud máxima permitida, se sella.
		if path.is_empty() or path.size() > max_length_corridor:
			puertas_aisladas.append(pA)
			puertas_aisladas.append(pB)
		else:
			var camino_completo = [inicio] + Array(path) + [fin]
			for punto in camino_completo:
				for x in range(-1, 2):
					for y in range(-1, 2):
						var pos_pasillo = Vector2(punto.x + x, punto.y + y)
						if not grid.has(pos_pasillo): grid[pos_pasillo] = {}
						if not grid[pos_pasillo].has("floors"):
							grid[pos_pasillo]["floors"] = {
								"source_id": id_source_piso, "atlas_coords": atlas_piso_sellado, "alternative_tile": 0
							}
							celdas_pasillo.append(pos_pasillo)

	puertas_pendientes = puertas_aisladas + puertas_pendientes
	
	for pos in celdas_pasillo:
		_evaluar_y_colocar_muro_pasillo(pos, Vector2.UP, muro_arriba)
		_evaluar_y_colocar_muro_pasillo(pos, Vector2.DOWN, muro_abajo)
		_evaluar_y_colocar_muro_pasillo(pos, Vector2.LEFT, muro_izquierda)
		_evaluar_y_colocar_muro_pasillo(pos, Vector2.RIGHT, muro_derecha)

func _evaluar_y_colocar_muro_pasillo(pos: Vector2, dir: Vector2, atlas_muro: Vector2i):
	var vecino = pos + dir
	if not grid.has(vecino) or not grid[vecino].has("floors"):
		grid[pos]["walls"] = {
			"source_id": id_source_muros,
			"atlas_coords": atlas_muro,
			"alternative_tile": 0
		}

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
