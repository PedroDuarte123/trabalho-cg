extends Node2D
class_name FlashlightDummy

signal target_entered(target: Node2D)
signal target_exited(target: Node2D)

@export var enabled: bool = true:
	set(value):
		enabled = value
		_update_enabled()

@export_range(50.0, 2500.0, 10.0) var beam_length: float = 650.0:
	set(value):
		beam_length = value
		_update_beam_geometry()
		_update_light_texture_scale()

@export_range(1.0, 179.0, 1.0) var beam_angle_deg: float = 35.0:
	set(value):
		beam_angle_deg = value
		_update_beam_geometry()
		_update_light_texture()

@export_range(0.0, 1.0, 0.01) var edge_softness: float = 0.12:
	set(value):
		edge_softness = value
		_update_light_texture()

@export_range(0.0, 1.0, 0.01) var radial_falloff: float = 0.9:
	set(value):
		radial_falloff = value
		_update_light_texture()

@export var target_collision_mask: int = 1:
	set(value):
		target_collision_mask = value
		if is_instance_valid(_beam_area):
			_beam_area.collision_mask = target_collision_mask

@export var occluder_collision_mask: int = 0

@export var target_group: StringName = &"light_target"

@export var debug_draw: bool = true:
	set(value):
		debug_draw = value
		queue_redraw()

@onready var _light: PointLight2D = $Light
@onready var _beam_area: Area2D = $BeamArea
@onready var _beam_collision: CollisionPolygon2D = $BeamArea/BeamCollision

var _prev_overlapping: Dictionary = {}

func _ready() -> void:
	_beam_area.monitoring = true
	_beam_area.monitorable = false
	_beam_area.collision_layer = 0
	_beam_area.collision_mask = target_collision_mask

	_update_light_texture()
	_update_light_texture_scale()
	_update_beam_geometry()
	_update_enabled()

func _process(_delta: float) -> void:
	_aim_to_mouse()
	_emit_overlap_signals()

func _draw() -> void:
	if not debug_draw:
		return

	draw_circle(Vector2.ZERO, 8.0, Color(1, 1, 1, 0.9))

	var half_angle := deg_to_rad(beam_angle_deg) * 0.5
	var left := Vector2(beam_length, 0).rotated(-half_angle)
	var right := Vector2(beam_length, 0).rotated(half_angle)
	var col := Color(1, 1, 0.4, 0.7)
	draw_line(Vector2.ZERO, left, col, 2.0)
	draw_line(Vector2.ZERO, right, col, 2.0)
	draw_arc(Vector2.ZERO, beam_length, -half_angle, half_angle, 32, col, 2.0)

func _aim_to_mouse() -> void:
	var dir := get_global_mouse_position() - global_position
	if dir.length_squared() <= 0.0001:
		return
	global_rotation = dir.angle()

func _update_enabled() -> void:
	if not is_inside_tree():
		return
	_light.visible = enabled
	_beam_area.monitoring = enabled
	set_process(enabled)
	queue_redraw()

func _update_beam_geometry() -> void:
	if not is_inside_tree():
		return

	var half_angle := deg_to_rad(beam_angle_deg) * 0.5
	var base_half_width := 10.0
	var left := Vector2(beam_length, 0).rotated(-half_angle)
	var right := Vector2(beam_length, 0).rotated(half_angle)

	_beam_collision.polygon = PackedVector2Array([
		Vector2(0, -base_half_width),
		left,
		right,
		Vector2(0, base_half_width),
	])

	queue_redraw()

func _update_light_texture_scale() -> void:
	if not is_inside_tree():
		return

	# Nosso texture é 256x256 e o cone vai do centro até a borda direita.
	# Ou seja, o "raio" útil é 128px.
	_light.texture_scale = beam_length / 128.0

func _update_light_texture() -> void:
	if not is_inside_tree():
		return

	_light.texture = _generate_cone_texture(256, 256)
	# Faz o cone "apontar" pro +X (direita) no espaço local.
	_light.rotation = 0.0

func _emit_overlap_signals() -> void:
	if not enabled:
		return

	var overlapping := _beam_area.get_overlapping_bodies()
	var now: Dictionary = {}
	for body in overlapping:
		if body is Node2D:
			now[body] = true

	for body in now.keys():
		if not _prev_overlapping.has(body):
			target_entered.emit(body)

	for body in _prev_overlapping.keys():
		if not now.has(body):
			target_exited.emit(body)

	_prev_overlapping = now

func get_lit_targets() -> Array[Node2D]:
	# Retorna alvos que estão dentro do cone E (opcionalmente) sem obstrução.
	var result: Array[Node2D] = []
	if not enabled:
		return result

	var overlapping := _beam_area.get_overlapping_bodies()
	for body in overlapping:
		if not (body is Node2D):
			continue
		var target := body as Node2D
		if target_group != &"" and not target.is_in_group(target_group):
			continue
		if _has_line_of_sight(target):
			result.append(target)

	return result

func _has_line_of_sight(target: Node2D) -> bool:
	if occluder_collision_mask == 0:
		return true

	var space := get_world_2d().direct_space_state
	var params := PhysicsRayQueryParameters2D.create(global_position, target.global_position)
	params.exclude = [self, _beam_area]
	params.collision_mask = occluder_collision_mask

	var hit := space.intersect_ray(params)
	# Se bateu em algo antes do alvo, considera obstruído.
	return hit.is_empty()

func _generate_cone_texture(w: int, h: int) -> Texture2D:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	# Light2D centraliza a textura no nó. Então a origem do cone precisa ser o centro.
	var center: Vector2 = Vector2(w * 0.5, h * 0.5)
	var max_r: float = float(w) * 0.5
	var half_angle: float = deg_to_rad(beam_angle_deg) * 0.5
	var softness: float = maxf(edge_softness, 0.0001)

	for y in range(h):
		for x in range(w):
			var p := Vector2(float(x), float(y))
			var v := p - center
			# Mantém o cone apenas no semiplano da direita.
			if v.x < 0.0:
				continue
			var r: float = v.length()
			if r <= 0.0001:
				continue
			var a: float = absf(atan2(v.y, v.x))
			if a > (half_angle + softness):
				continue

			var edge_t: float = 1.0
			if a > half_angle:
				edge_t = 1.0 - ((a - half_angle) / softness)

			var radial_t: float = 1.0 - clampf(r / max_r, 0.0, 1.0)
			radial_t = pow(radial_t, lerpf(0.2, 3.0, radial_falloff))

			var alpha: float = clampf(edge_t * radial_t, 0.0, 1.0)
			# Cor da máscara: branco no alfa.
			img.set_pixel(x, y, Color(1, 1, 1, alpha))

	var tex := ImageTexture.create_from_image(img)
	return tex
