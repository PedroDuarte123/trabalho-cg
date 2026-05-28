extends Node2D

const TILE_SIZE := 32
const WAIT_DURATION := 0.5


@onready var platform: AnimatableBody2D = $platform


# =========================
# Configurações
# =========================

@export_group("Movimento")

@export var move_speed: float = 3.0
@export var distance_multiplier: int = 3

## true = horizontal | false = vertical
@export var move_horizontal: bool = true


enum HorizontalDirection {
	DIREITA = 1,
	ESQUERDA = -1
}

enum VerticalDirection {
	BAIXO = 1,
	CIMA = -1
}

@export var horizontal_direction: HorizontalDirection = HorizontalDirection.DIREITA
@export var vertical_direction: VerticalDirection = VerticalDirection.BAIXO


@export_group("Lanterna")

## Marcado = plataforma só se move iluminada
## Desmarcado = plataforma sempre se move
@export var require_flashlight: bool = false


# =========================
# Estado interno
# =========================

var follow: Vector2 = Vector2.ZERO

var _distance: float
var _platform_center: float = TILE_SIZE

var _tween: Tween = null
var _is_lit: bool = false


# =========================
# Ciclo de vida
# =========================

func _ready() -> void:
	_distance = TILE_SIZE * distance_multiplier

	platform.add_to_group("light_target")

	if require_flashlight:
		_connect_to_flashlight()
	else:
		_start_movement()


func _physics_process(_delta: float) -> void:
	platform.position = platform.position.lerp(follow, 0.5)


# =========================
# Movimento
# =========================

func _start_movement() -> void:
	var move_direction := _get_move_direction()

	var duration := move_direction.length() / (move_speed * _platform_center)

	_tween = create_tween()
	_tween.set_loops()
	_tween.set_trans(Tween.TRANS_LINEAR)
	_tween.set_ease(Tween.EASE_IN_OUT)

	_tween.tween_property(
		self,
		"follow",
		move_direction,
		duration
	).set_delay(WAIT_DURATION)

	_tween.tween_property(
		self,
		"follow",
		Vector2.ZERO,
		duration
	).set_delay(WAIT_DURATION)


func _get_move_direction() -> Vector2:
	if move_horizontal:
		return Vector2.RIGHT * _distance * horizontal_direction

	return Vector2.DOWN * _distance * vertical_direction


# =========================
# Lanterna
# =========================

func _connect_to_flashlight() -> void:
	await get_tree().process_frame

	var players := get_tree().get_nodes_in_group("player")

	if players.is_empty():
		push_warning("Nenhum player encontrado no grupo 'player'")
		return

	var flashlight = players[0].get_node_or_null("FlashlightDummy")

	if flashlight == null:
		push_warning("FlashlightDummy não encontrado no player")
		return

	flashlight.target_entered.connect(_on_light_entered)
	flashlight.target_exited.connect(_on_light_exited)
	flashlight.flashlight_toggled.connect(_on_flashlight_toggled)


func _on_light_entered(body: Node2D) -> void:
	if body != platform:
		return

	if _is_lit:
		return

	_is_lit = true

	if _tween:
		_tween.play()
	else:
		_start_movement()


func _on_light_exited(body: Node2D) -> void:
	if body != platform:
		return

	_is_lit = false

	if _tween:
		_tween.pause()


func _on_flashlight_toggled(is_on: bool) -> void:
	if _tween == null:
		return

	if is_on and _is_lit:
		_tween.play()
	else:
		_tween.pause()
