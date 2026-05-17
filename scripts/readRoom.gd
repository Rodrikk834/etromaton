extends Node2D
class_name CuartoPrefab

@export var tipo_cuarto : String = "normal"

@export_category("Estilo de Muros para Pasillos/Sellos")
@export var id_source_muros : int = 1
@export var muro_arriba : Vector2i = Vector2i(0, 1)
@export var muro_abajo : Vector2i = Vector2i(1, 0)
@export var muro_izquierda : Vector2i = Vector2i(1, 1)
@export var muro_derecha : Vector2i = Vector2i(0, 0)

const TILE_SIZE : float = 16.0 

func exportar_datos_matematicos(id_asignado : int) -> Dictionary:
	var dict_cuarto = {
		"id": id_asignado,
		"tipo": tipo_cuarto,
		"direcciones_soportadas": [],
		"puertas": [],
		"tiles_ocupados": [],
		"bounding_box": Rect2(),
		"estilo_muros": {
			"source_id": id_source_muros,
			"arriba": muro_arriba,
			"abajo": muro_abajo,
			"izquierda": muro_izquierda,
			"derecha": muro_derecha
		}
	}
	
	_escanear_puertas(dict_cuarto)
	_escanear_tiles_y_limites(dict_cuarto)
	
	return dict_cuarto

# =========================================================
# FUNCIONES INTERNAS DE ESCANEO
# =========================================================
func _escanear_puertas(dict_cuarto : Dictionary):
	var nodos_puerta = find_children("*", "Marker2D")
	
	for puerta in nodos_puerta:
		var direccion_limpia = Vector2.RIGHT.rotated(puerta.global_rotation).round()
		var pos_logica = (puerta.position / TILE_SIZE).floor()
		
		dict_cuarto["puertas"].append({
			"posicion_local": pos_logica,
			"direccion": direccion_limpia
		})
		
		if not direccion_limpia in dict_cuarto["direcciones_soportadas"]:
			dict_cuarto["direcciones_soportadas"].append(direccion_limpia)

func _escanear_tiles_y_limites(dict_cuarto : Dictionary):
	var capas_tilemap = find_children("*", "TileMapLayer")
	
	var min_x = INF
	var min_y = INF
	var max_x = -INF
	var max_y = -INF
	
	for capa in capas_tilemap:
		var nombre_capa = capa.name 
		var celdas_usadas = capa.get_used_cells()
		
		for celda in celdas_usadas:
			var origen_id = capa.get_cell_source_id(celda)
			var atlas_xy = capa.get_cell_atlas_coords(celda)
			var alternativo = capa.get_cell_alternative_tile(celda)
			
			dict_cuarto["tiles_ocupados"].append({
				"posicion_local": Vector2(celda.x, celda.y),
				"nombre_capa": nombre_capa,
				"source_id": origen_id,
				"atlas_coords": atlas_xy,
				"alternative_tile": alternativo
			})
			
			if celda.x < min_x: min_x = celda.x
			if celda.x > max_x: max_x = celda.x
			if celda.y < min_y: min_y = celda.y
			if celda.y > max_y: max_y = celda.y
			
	if min_x != INF:
		var ancho = (max_x - min_x) + 1
		var alto = (max_y - min_y) + 1
		dict_cuarto["bounding_box"] = Rect2(min_x, min_y, ancho, alto)
