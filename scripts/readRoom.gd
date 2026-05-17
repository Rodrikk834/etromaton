extends Node2D
class_name CuartoPrefab

@export var tipo_cuarto : String = "normal"
const TILE_SIZE : float = 16.0 

func exportar_datos_matematicos(id_asignado : int) -> Dictionary:
	var dict_cuarto = {
		"id": id_asignado,
		"tipo": tipo_cuarto,
		"direcciones_soportadas": [],
		"puertas": [],
		"tiles_ocupados": [],
		"bounding_box": Rect2()
	}
	
	_escanear_puertas(dict_cuarto)
	_escanear_tiles_y_limites(dict_cuarto)
	
	return dict_cuarto

# =========================================================
# FUNCIONES INTERNAS DE ESCANEO
# =========================================================
func _escanear_puertas(dict_cuarto : Dictionary):
	# Busca todos los Marker2D en el cuarto, sin importar dónde estén anidados
	var nodos_puerta = find_children("*", "Marker2D")
	
	for puerta in nodos_puerta:
		# 1. Obtenemos la dirección limpia hacia donde mira la puerta (Vector2)
		var direccion_limpia = Vector2.RIGHT.rotated(puerta.global_rotation).round()
		
		# 2. Convertimos la posición en píxeles a coordenadas lógicas de tile
		var pos_logica = (puerta.position / TILE_SIZE).floor()
		
		# 3. Guardamos la puerta en la lista
		dict_cuarto["puertas"].append({
			"posicion_local": pos_logica,
			"direccion": direccion_limpia
		})
		
		# 4. Registramos esta dirección como "soportada" si no estaba ya
		if not direccion_limpia in dict_cuarto["direcciones_soportadas"]:
			dict_cuarto["direcciones_soportadas"].append(direccion_limpia)

func _escanear_tiles_y_limites(dict_cuarto : Dictionary):
	# Busca TODOS los nodos TileMapLayer en el cuarto ("floors", "walls", etc.)
	var capas_tilemap = find_children("*", "TileMapLayer")
	
	# Variables de apoyo para calcular la caja delimitadora (Bounding Box)
	var min_x = INF
	var min_y = INF
	var max_x = -INF
	var max_y = -INF
	
	for capa in capas_tilemap:
		# Guardamos el nombre exacto del nodo (ej. "floors") para saber dónde dibujarlo después
		var nombre_capa = capa.name 
		var celdas_usadas = capa.get_used_cells()
		
		for celda in celdas_usadas:
			# Extraemos la información atómica del tile
			var origen_id = capa.get_cell_source_id(celda)
			var atlas_xy = capa.get_cell_atlas_coords(celda)
			var alternativo = capa.get_cell_alternative_tile(celda)
			
			# Lo inyectamos al diccionario
			dict_cuarto["tiles_ocupados"].append({
				"posicion_local": Vector2(celda.x, celda.y),
				"nombre_capa": nombre_capa,
				"source_id": origen_id,
				"atlas_coords": atlas_xy,
				"alternative_tile": alternativo
			})
			
			# Actualizamos los límites para la Bounding Box
			if celda.x < min_x: min_x = celda.x
			if celda.x > max_x: max_x = celda.x
			if celda.y < min_y: min_y = celda.y
			if celda.y > max_y: max_y = celda.y
			
	# Si el cuarto tiene al menos un tile, creamos su caja delimitadora matemática
	if min_x != INF:
		var ancho = (max_x - min_x) + 1
		var alto = (max_y - min_y) + 1
		dict_cuarto["bounding_box"] = Rect2(min_x, min_y, ancho, alto)
