extends Node2D
class_name CameraIntroPan

@export var enabled: bool = true
@export var auto_start: bool = true
@export_range(0.0, 30.0, 0.1) var start_delay: float = 0.3
@export_range(0.1, 30.0, 0.1) var duration: float = 5.0
@export_range(0.0, 30.0, 0.1) var hold_end: float = 0.25

@export var override_start_y: bool = false
@export var start_y: float = 0.0
@export var override_end_y: bool = false
@export var end_y: float = 0.0

@export var player_group: StringName = &"player"
@export var player_camera_path: NodePath = NodePath("Camera2D")
@export var player_animated_sprite_path: NodePath = NodePath("AnimatedSprite2D")
@export var idle_animation_name: StringName = &"Idle"

@export var block_player_while_playing: bool = true
@export var block_player_idle_process: bool = true
@export var block_player_input: bool = true
@export var force_player_idle_animation: bool = true

@export var tiles_root_path: NodePath = NodePath("Tiles")

@onready var _intro_camera: Camera2D = $Camera2D
@onready var _start_marker: Marker2D = $Start
@onready var _end_marker: Marker2D = $End

var _playing: bool = false
var _blocked_player: Node = null
var _blocked_player_prev: Dictionary = {}

func _ready() -> void:
	if auto_start and enabled:
		call_deferred("play")

func play() -> void:
	if _playing or not enabled:
		return
	_playing = true

	# Espera 1 frame pra garantir que o resto da cena já entrou na árvore.
	await get_tree().process_frame

	var return_camera: Camera2D = get_viewport().get_camera_2d()
	var player := get_tree().get_first_node_in_group(player_group)
	if is_instance_valid(player):
		if block_player_while_playing:
			_block_player(player)

		var maybe_cam := player.get_node_or_null(player_camera_path)
		if maybe_cam is Camera2D:
			return_camera = maybe_cam

	if is_instance_valid(return_camera):
		_intro_camera.zoom = return_camera.zoom

	_intro_camera.global_position = _compute_end_position(return_camera)
	_intro_camera.make_current()

	if start_delay > 0.0:
		await get_tree().create_timer(start_delay).timeout

	var end_pos := return_camera.global_position if is_instance_valid(return_camera) else _compute_start_position(return_camera)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_intro_camera, "global_position", end_pos, duration)
	await tween.finished

	if hold_end > 0.0:
		await get_tree().create_timer(hold_end).timeout

	if is_instance_valid(return_camera):
		return_camera.make_current()

	_unblock_player()

	_playing = false

func _block_player(player: Node) -> void:
	if not is_instance_valid(player):
		return
	if is_instance_valid(_blocked_player):
		return

	_blocked_player = player
	_blocked_player_prev.clear()
	_blocked_player_prev["physics"] = player.is_physics_processing()
	_blocked_player_prev["idle"] = player.is_processing()

	if block_player_input:
		if player.has_method("is_processing_input"):
			_blocked_player_prev["input"] = player.is_processing_input()
		if player.has_method("is_processing_unhandled_input"):
			_blocked_player_prev["unhandled_input"] = player.is_processing_unhandled_input()
		if player.has_method("is_processing_unhandled_key_input"):
			_blocked_player_prev["unhandled_key_input"] = player.is_processing_unhandled_key_input()

	# Para CharacterBody2D, zera velocidade pra não “carregar” movimento.
	if player is CharacterBody2D:
		(player as CharacterBody2D).velocity = Vector2.ZERO

	if force_player_idle_animation:
		_force_player_idle(player)

	player.set_physics_process(false)
	if block_player_idle_process:
		player.set_process(false)
	if block_player_input:
		if player.has_method("set_process_input"):
			player.set_process_input(false)
		if player.has_method("set_process_unhandled_input"):
			player.set_process_unhandled_input(false)
		if player.has_method("set_process_unhandled_key_input"):
			player.set_process_unhandled_key_input(false)

func _force_player_idle(player: Node) -> void:
	if not is_instance_valid(player):
		return
	var sprite := player.get_node_or_null(player_animated_sprite_path)
	if sprite is AnimatedSprite2D:
		var anim_sprite := sprite as AnimatedSprite2D
		if idle_animation_name != &"":
			anim_sprite.play(idle_animation_name)
		# Offset padrão do seu Idle é 0; evita ficar com offset de corrida/pulo.
		anim_sprite.offset.y = 0

func _unblock_player() -> void:
	if not is_instance_valid(_blocked_player):
		_blocked_player = null
		_blocked_player_prev.clear()
		return

	_blocked_player.set_physics_process(_blocked_player_prev.get("physics", true))
	_blocked_player.set_process(_blocked_player_prev.get("idle", true))

	if block_player_input:
		if _blocked_player.has_method("set_process_input"):
			_blocked_player.set_process_input(_blocked_player_prev.get("input", true))
		if _blocked_player.has_method("set_process_unhandled_input"):
			_blocked_player.set_process_unhandled_input(_blocked_player_prev.get("unhandled_input", true))
		if _blocked_player.has_method("set_process_unhandled_key_input"):
			_blocked_player.set_process_unhandled_key_input(_blocked_player_prev.get("unhandled_key_input", true))

	_blocked_player = null
	_blocked_player_prev.clear()

func _markers_configured() -> bool:
	return _start_marker.global_position.distance_to(_end_marker.global_position) > 1.0

func _compute_start_position(return_camera: Camera2D) -> Vector2:
	if _markers_configured():
		return _start_marker.global_position

	var bounds: Array[float] = _try_get_level_bounds_x()
	if bounds.is_empty():
		return _start_marker.global_position

	var cam_y: float
	if override_start_y:
		cam_y = start_y
	else:
		cam_y = return_camera.global_position.y if is_instance_valid(return_camera) else _start_marker.global_position.y
	return Vector2(_fit_camera_center_x(bounds[0], bounds[1], return_camera), cam_y)

func _compute_end_position(return_camera: Camera2D) -> Vector2:
	if _markers_configured():
		return _end_marker.global_position

	var bounds: Array[float] = _try_get_level_bounds_x()
	if bounds.is_empty():
		return _end_marker.global_position

	var cam_y: float
	if override_end_y:
		cam_y = end_y
	else:
		cam_y = return_camera.global_position.y if is_instance_valid(return_camera) else _end_marker.global_position.y
	return Vector2(_fit_camera_center_x(bounds[1], bounds[0], return_camera), cam_y)

func _fit_camera_center_x(target_edge_x: float, other_edge_x: float, return_camera: Camera2D) -> float:
	# Ajusta para a câmera não mostrar “fora do mapa” (aproximação baseada no viewport).
	var zoom_x := _intro_camera.zoom.x
	if is_instance_valid(return_camera):
		zoom_x = return_camera.zoom.x

	var half_view_w := get_viewport_rect().size.x * 0.5
	var half_world_w := half_view_w / maxf(zoom_x, 0.0001)

	var min_x := minf(target_edge_x, other_edge_x) + half_world_w
	var max_x := maxf(target_edge_x, other_edge_x) - half_world_w
	if max_x < min_x:
		return (minf(target_edge_x, other_edge_x) + maxf(target_edge_x, other_edge_x)) * 0.5
	return clampf(target_edge_x, min_x, max_x)


func _try_get_level_bounds_x() -> Array[float]:
	# Retorna [min_x, max_x] em coordenadas globais, baseado no TileMap.
	var tiles_root := get_parent().get_node_or_null(tiles_root_path)
	var layers: Array[TileMapLayer] = []

	if is_instance_valid(tiles_root):
		layers = _collect_tile_layers(tiles_root)
	else:
		layers = _collect_tile_layers(get_tree().current_scene)

	var has_any := false
	var min_x := INF
	var max_x := -INF

	for layer in layers:
		if not is_instance_valid(layer):
			continue
		if not layer.has_method("get_used_rect"):
			continue

		var rect: Rect2i = layer.get_used_rect()
		if rect.size.x <= 0 or rect.size.y <= 0:
			continue

		var tile_size := Vector2(16, 16)
		if layer.tile_set:
			tile_size = Vector2(layer.tile_set.tile_size)

		var left_cell := rect.position
		var right_cell := rect.position + Vector2i(rect.size.x - 1, 0)

		var left_center := layer.to_global(layer.map_to_local(left_cell))
		var right_center := layer.to_global(layer.map_to_local(right_cell))

		var left_edge := left_center.x - tile_size.x * 0.5
		var right_edge := right_center.x + tile_size.x * 0.5

		min_x = minf(min_x, left_edge)
		max_x = maxf(max_x, right_edge)
		has_any = true

	if not has_any:
		return []

	return [min_x, max_x]

func _collect_tile_layers(root: Node) -> Array[TileMapLayer]:
	var result: Array[TileMapLayer] = []
	if not is_instance_valid(root):
		return result

	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is TileMapLayer:
			result.append(n)
		for child in n.get_children():
			if child is Node:
				stack.append(child)

	return result
