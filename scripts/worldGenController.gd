extends Node
class_name WorldGenerator

@export_category("Configuración de Generación")
@export var semilla_inicial : int = 0
@export var limite_cuartos : int = 100

@export_category("Configuración de Pasillos (A*)")
@export var max_length_corridor : int = 5

@export_category("Catálogo de Escenas")
@export var escenas_iniciales : Array[PackedScene] = []
@export var escenas_cuartos : Array[PackedScene] = []

@export var categorias_especiales : Array[CategoriaCuarto] = []
@export var escenas_relleno : Array[PackedScene] = []

@export_category("Configuración Visual (Fallback)")
@export var id_source_muros : int = 1
@export var muro_arriba : Vector2i = Vector2i(0, 1)
@export var muro_abajo : Vector2i = Vector2i(1, 0)
@export var muro_izquierda : Vector2i = Vector2i(1, 1)
@export var muro_derecha : Vector2i = Vector2i(0, 0)
@export var id_source_piso : int = 1
@export var atlas_piso_sellado : Vector2i = Vector2i(0, 4)

@export_category("Entidades e Interacción")
@export var escena_contenedor : PackedScene
@export var prob_spawn_contenedor : float = 0.5 

const TILE_SIZE_GEN : float = 16.0

@onready var region_navegacion = $NavigationRegion2D

var rng := RandomNumberGenerator.new()
var grid : Dictionary = {}

var base_de_datos_iniciales : Array = []
var base_de_datos_cuartos : Array = []
var base_de_datos_especiales : Array = [] 
var base_de_datos_relleno : Array = []

var puertas_pendientes : Array = []
var contenedores_pendientes : Array = []
var cuartos_generados : int = 0
var contador_instancias : int = 0

func _ready():
	if semilla_inicial == 0:
		rng.randomize() 
	else:
		rng.seed = semilla_inicial
		
	# Guarda la semilla globalmente para que los contenedores puedan acceder a ella
	GlobalController.world_seed = rng.seed
	print("Semilla del mundo generada: ", GlobalController.world_seed)

	preparar_catalogo()
	
	generar_mapa()
	_inyectar_cuartos_finales()
	_construir_pasillos_astar()
	_sellar_puertas_sobrantes()
	
	dibujar_mapa_final()
	_instanciar_entidades()
	
	_actualizar_mapa_navegacion()

func _instanciar_entidades():
	if escena_contenedor == null:
		push_warning("WorldGenerator: No se asignó escena_contenedor en el Inspector.")
		return
		
	for cont_data in contenedores_pendientes:
		var nuevo_contenedor = escena_contenedor.instantiate()
		
		var pos_global_pixeles = (cont_data.pos_grid_cuarto * TILE_SIZE_GEN) + cont_data.pos_local_pixeles
		
		nuevo_contenedor.global_position = pos_global_pixeles
		nuevo_contenedor.global_rotation = cont_data.rotacion
		
		# Se agregan al NavigationRegion2D para mantener orden en la escena
		region_navegacion.add_child(nuevo_contenedor)

func _actualizar_mapa_navegacion():
	await get_tree().physics_frame
	
	if not region_navegacion: return
	
	var nav_poly = region_navegacion.navigation_polygon
	if nav_poly == null:
		region_navegacion.navigation_polygon = NavigationPolygon.new()
		nav_poly = region_navegacion.navigation_polygon
	
	nav_poly.parsed_geometry_type = NavigationPolygon.PARSED_GEOMETRY_BOTH
	nav_poly.source_geometry_mode = NavigationPolygon.SOURCE_GEOMETRY_ROOT_NODE_CHILDREN
	
	nav_poly.agent_radius = 10.0 
	nav_poly.cell_size = 4.0 
	
	region_navegacion.bake_navigation_polygon()
	
	for nodo in get_tree().get_nodes_in_group("navigation"):
		if nodo is TileMapLayer: continue
		if nodo is Node2D:
			_cut_out_manual(nodo)

func _cut_out_manual(node: Node2D):
	var polygon = region_navegacion.navigation_polygon
	if not polygon: return
	
	var collision_shape: CollisionShape2D = null
	for child in node.get_children():
		if child is CollisionShape2D:
			collision_shape = child
			break
			
	if collision_shape and collision_shape.shape is RectangleShape2D:
		var rect_shape = collision_shape.shape as RectangleShape2D
		var extents = rect_shape.size / 2.0 
		
		var vertices = [
			Vector2(-extents.x, -extents.y),
			Vector2(extents.x, -extents.y),
			Vector2(extents.x, extents.y),
			Vector2(-extents.x, extents.y)
		]

		var new_outline = PackedVector2Array()
		var shape_transform = collision_shape.global_transform
		for vertex in vertices:
			new_outline.append(shape_transform * vertex)

		polygon.add_outline(new_outline)
		polygon.make_polygons_from_outlines()
		region_navegacion.navigation_polygon = polygon
		
func preparar_catalogo():
	base_de_datos_iniciales = _procesar_array_escenas(escenas_iniciales)
	base_de_datos_cuartos = _procesar_array_escenas(escenas_cuartos)
	base_de_datos_relleno = _procesar_array_escenas(escenas_relleno)
	
	base_de_datos_especiales.clear()
	for categoria in categorias_especiales:
		if categoria != null and categoria.variantes.size() > 0:
			var categoria_procesada = _procesar_array_escenas(categoria.variantes)
			if categoria_procesada.size() > 0:
				base_de_datos_especiales.append(categoria_procesada)

func _procesar_array_escenas(array_escenas: Array) -> Array:
	var base_datos = []
	for i in range(array_escenas.size()):
		var escena = array_escenas[i]
		if escena is PackedScene: 
			var cuarto_temp = escena.instantiate()
			if cuarto_temp.has_method("exportar_datos_matematicos"):
				var datos = cuarto_temp.exportar_datos_matematicos(i)
				if datos.puertas.size() > 0:
					base_datos.append(datos)
				else:
					push_warning("Cuarto sin puertas ignorado: " + cuarto_temp.name)
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
		
		var p_global = posicion_global_cuarto + puerta_local.posicion_local
		var pos_adentro = p_global - puerta_local.direccion
		var piso_heredado = null
		
		if grid.has(pos_adentro) and grid[pos_adentro].has("floors"):
			piso_heredado = grid[pos_adentro]["floors"]
		
		puertas_pendientes.append({
			"posicion_global": p_global,
			"direccion": puerta_local.direccion,
			"id_cuarto": contador_instancias,
			"estilo_piso": piso_heredado,
			"estilo_muros": datos_cuarto["estilo_muros"]
		})
		
	# Procesar contenedores del cuarto
	if datos_cuarto.has("contenedores"):
		for cont_data in datos_cuarto.contenedores:
			if rng.randf() <= prob_spawn_contenedor:
				contenedores_pendientes.append({
					"pos_grid_cuarto": posicion_global_cuarto,
					"pos_local_pixeles": cont_data.posicion_local_pixeles,
					"rotacion": cont_data.rotacion
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
		
		var candidatos_validos = []
		
		for i in range(puertas_pendientes.size()):
			var pB = puertas_pendientes[i]
			if pA.id_cuarto == pB.id_cuarto: continue
				
			var dist_manhattan = abs(pA.posicion_global.x - pB.posicion_global.x) + abs(pA.posicion_global.y - pB.posicion_global.y)
			
			if dist_manhattan > max_length_corridor:
				continue
				
			candidatos_validos.append({"index": i, "dist": dist_manhattan})
			
		candidatos_validos.sort_custom(func(a, b): return a.dist < b.dist)
		
		var pB_index = -1
		var best_path = []
		
		for cand in candidatos_validos:
			var i = cand.index
			var pB = puertas_pendientes[i]
			
			var inicio_fuera = Vector2i((pA.posicion_global + pA.direccion).round())
			var fin_fuera = Vector2i((pB.posicion_global + pB.direccion).round())
			
			astar_grid.set_point_solid(Vector2i(pA.posicion_global.round()), false)
			astar_grid.set_point_solid(Vector2i(pB.posicion_global.round()), false)
			astar_grid.set_point_solid(inicio_fuera, false)
			astar_grid.set_point_solid(fin_fuera, false)
			
			var test_path = astar_grid.get_id_path(inicio_fuera, fin_fuera)
			
			if not test_path.is_empty() and test_path.size() <= max_length_corridor:
				best_path = test_path
				pB_index = i
				break 
				
		if pB_index == -1:
			puertas_aisladas.append(pA)
			continue
			
		var pB = puertas_pendientes.pop_at(pB_index)
		
		var inicio = Vector2i(pA.posicion_global.round())
		var fin = Vector2i(pB.posicion_global.round())
		
		var piso_usar = pA.estilo_piso if pA.estilo_piso != null else {
			"source_id": id_source_piso, "atlas_coords": atlas_piso_sellado, "alternative_tile": 0
		}
		
		var camino_completo = [inicio] + Array(best_path) + [fin]
		for punto in camino_completo:
			for x in range(-1, 2):
				for y in range(-1, 2):
					var pos_pasillo = Vector2(punto.x + x, punto.y + y)
					if not grid.has(pos_pasillo): grid[pos_pasillo] = {}
					
					if grid[pos_pasillo].has("walls"):
						grid[pos_pasillo].erase("walls")
						
					if not grid[pos_pasillo].has("floors"):
						grid[pos_pasillo]["floors"] = piso_usar
						celdas_pasillo.append({
							"pos": pos_pasillo,
							"muros": pA.estilo_muros
						})

	puertas_pendientes = puertas_aisladas + puertas_pendientes
	
	for celda_info in celdas_pasillo:
		var pos = celda_info.pos
		var muros = celda_info.muros
		var s_id = muros.source_id
		
		_evaluar_y_colocar_muro_pasillo(pos, Vector2.UP, s_id, muros.arriba)
		_evaluar_y_colocar_muro_pasillo(pos, Vector2.DOWN, s_id, muros.abajo)
		_evaluar_y_colocar_muro_pasillo(pos, Vector2.LEFT, s_id, muros.izquierda)
		_evaluar_y_colocar_muro_pasillo(pos, Vector2.RIGHT, s_id, muros.derecha)

func _evaluar_y_colocar_muro_pasillo(pos: Vector2, dir: Vector2, id_source: int, atlas_muro: Vector2i):
	var vecino = pos + dir
	if not grid.has(vecino) or not grid[vecino].has("floors"):
		grid[pos]["walls"] = {
			"source_id": id_source,
			"atlas_coords": atlas_muro,
			"alternative_tile": 0
		}

func _sellar_puertas_sobrantes():
	for puerta in puertas_pendientes:
		var estilo_muros = puerta.estilo_muros
		var id_source = estilo_muros.source_id
		var atlas_muro : Vector2i
		var perp : Vector2
		var offset_correccion := Vector2.ZERO
		
		var dir_i = Vector2i(puerta.direccion.round())
		
		match dir_i:
			Vector2i.UP:
				atlas_muro = estilo_muros.arriba
				perp = Vector2.RIGHT
				offset_correccion = Vector2(0, 1)
			Vector2i.DOWN:
				atlas_muro = estilo_muros.abajo
				perp = Vector2.RIGHT
			Vector2i.LEFT:
				atlas_muro = estilo_muros.izquierda
				perp = Vector2.DOWN
				offset_correccion = Vector2(1, 0)
			Vector2i.RIGHT:
				atlas_muro = estilo_muros.derecha
				perp = Vector2.DOWN
		
		var piso_usar = puerta.estilo_piso if puerta.estilo_piso != null else {
			"source_id": id_source_piso, "atlas_coords": atlas_piso_sellado, "alternative_tile": 0
		}
		
		for i in range(-1, 2):
			var pos_relleno = puerta.posicion_global + (perp * i) + offset_correccion
			if not grid.has(pos_relleno): grid[pos_relleno] = {}
			if not grid[pos_relleno].has("floors"):
				grid[pos_relleno]["floors"] = piso_usar
			grid[pos_relleno]["walls"] = {
				"source_id": id_source, "atlas_coords": atlas_muro, "alternative_tile": 0
			}
	puertas_pendientes.clear()

func dibujar_mapa_final():
	for celda_global in grid:
		var celda_vector_i = Vector2i(celda_global.x, celda_global.y)
		var capas = grid[celda_global]
		
		for nombre_capa in capas:
			var d = capas[nombre_capa]
			var ruta_nodo = NodePath(str(nombre_capa))
			var nodo_capa = region_navegacion.get_node_or_null(ruta_nodo)
			
			if nodo_capa and nodo_capa is TileMapLayer:
				nodo_capa.set_cell(celda_vector_i, d.source_id, d.atlas_coords, d.alternative_tile)
			else:
				push_warning("WorldGenerator: No se encontró el TileMapLayer llamado '%s'. ¡Créalo en la escena principal como hijo de NavigationRegion2D!" % str(nombre_capa))
