extends Node
class_name LightArmor

signal armor_broken
signal lit_changed(is_lit: bool)

@export_range(0.1, 999.0, 0.1) var max_armor: float = 3.0
@export_range(0.0, 999.0, 0.1) var drain_per_second: float = 1.0

@export var break_flash: bool = true
@export_range(0.01, 2.0, 0.01) var break_flash_duration: float = 0.18

@export var add_break_light: bool = true
@export_range(0.0, 20.0, 0.1) var break_light_energy: float = 6.0
@export_range(0.01, 3.0, 0.01) var break_light_duration: float = 0.22

@export var player_group: StringName = &"player"
@export var flashlight_node_name: StringName = &"FlashlightDummy"

@export_group("Debug")
@export var debug_log: bool = false
@export_range(0.05, 10.0, 0.05) var debug_log_interval: float = 0.5

var armor: float
var is_broken: bool = false

var _is_lit: bool = false
var _flashlight: Node = null
var _target: CanvasItem = null
var _original_modulate: Color
var _debug_accum: float = 0.0


func _ready() -> void:
	armor = max_armor
	_target = _resolve_target()
	if _target:
		_original_modulate = _target.modulate
	_connect_to_flashlight()
	set_process(true)


func _process(delta: float) -> void:
	if is_broken:
		return
	if not _is_lit:
		_debug_accum = 0.0
		return
	if drain_per_second <= 0.0:
		return

	armor = maxf(0.0, armor - (drain_per_second * delta))

	if debug_log:
		_debug_accum += delta
		if _debug_accum >= debug_log_interval:
			_debug_accum = 0.0
			var target_name := "<no target>"
			if _target != null:
				target_name = _target.name
			print("[LightArmor] target=", target_name, " armor=", snappedf(armor, 0.01), "/", max_armor)

	if armor <= 0.0:
		_break_armor()


func is_intact() -> bool:
	return not is_broken and armor > 0.0


func is_lit() -> bool:
	return _is_lit


func _resolve_target() -> CanvasItem:
	# LightArmor normalmente é adicionado como filho do inimigo.
	# Então o alvo é o pai (CanvasItem) para efeitos simples de modulate.
	var parent := get_parent()
	if parent is CanvasItem:
		return parent as CanvasItem
	return null


func _connect_to_flashlight() -> void:
	await get_tree().process_frame

	var players := get_tree().get_nodes_in_group(player_group)
	if players.is_empty():
		push_warning("LightArmor: nenhum player no grupo '%s'" % player_group)
		return

	var player := players[0] as Node
	var flashlight := player.get_node_or_null(String(flashlight_node_name))
	if flashlight == null:
		push_warning("LightArmor: nó '%s' não encontrado no player" % flashlight_node_name)
		return

	_flashlight = flashlight

	if _flashlight.has_signal("target_entered"):
		_flashlight.target_entered.connect(_on_light_entered)
	if _flashlight.has_signal("target_exited"):
		_flashlight.target_exited.connect(_on_light_exited)
	if _flashlight.has_signal("flashlight_toggled"):
		_flashlight.flashlight_toggled.connect(_on_flashlight_toggled)

	if debug_log:
		print("[LightArmor] connected to flashlight '", flashlight_node_name, "' on player '", player.name, "'")


func _on_light_entered(body: Node2D) -> void:
	var target := _target
	if target == null:
		return
	if body != target:
		return
	_set_lit(true)


func _on_light_exited(body: Node2D) -> void:
	var target := _target
	if target == null:
		return
	if body != target:
		return
	_set_lit(false)


func _on_flashlight_toggled(is_on: bool) -> void:
	if not is_on:
		_set_lit(false)


func _set_lit(value: bool) -> void:
	if _is_lit == value:
		return
	_is_lit = value
	lit_changed.emit(_is_lit)
	if debug_log:
		var target_name := "<no target>"
		if _target != null:
			target_name = _target.name
		print("[LightArmor] target=", target_name, " lit=", _is_lit)


func _break_armor() -> void:
	if is_broken:
		return

	is_broken = true
	_set_lit(false)
	armor = 0.0

	if break_flash:
		_play_break_flash()
	if add_break_light:
		_spawn_break_light()

	armor_broken.emit()
	if debug_log:
		var target_name := "<no target>"
		if _target != null:
			target_name = _target.name
		print("[LightArmor] target=", target_name, " ARMOR BROKEN")


func _play_break_flash() -> void:
	if _target == null:
		return

	var t := create_tween()
	t.set_trans(Tween.TRANS_SINE)
	t.set_ease(Tween.EASE_OUT)
	_target.modulate = _original_modulate
	t.tween_property(_target, "modulate", Color(1, 1, 1, 1), break_flash_duration * 0.5)
	t.tween_property(_target, "modulate", _original_modulate, break_flash_duration * 0.5)


func _spawn_break_light() -> void:
	if _target == null:
		return

	var light := PointLight2D.new()
	light.energy = break_light_energy
	light.color = Color(1, 0.98, 0.9, 1)
	light.shadow_enabled = false
	light.texture = null
	light.visible = true
	_target.add_child(light)

	var t := create_tween()
	t.tween_property(light, "energy", 0.0, break_light_duration)
	await t.finished
	if is_instance_valid(light):
		light.queue_free()
