extends Node2D

const SAVE_PATH := "user://savegame.cfg"
const SAVE_SECTION := "player"

@export var respawn_delay_seconds := 0.8

@onready var player: CharacterBody2D = $Player

var respawn_position: Vector2
var _is_respawning := false

var _death_overlay_rect: ColorRect


func _enter_tree() -> void:
	add_to_group("game")


func _ready() -> void:
	_ensure_death_overlay()

	respawn_position = player.global_position
	_load_checkpoint_if_any()

	if player.has_signal("died"):
		player.died.connect(_on_player_died)


func set_checkpoint(new_respawn_position: Vector2) -> void:
	respawn_position = new_respawn_position
	_save_checkpoint()
	if is_instance_valid(player) and player.has_method("reset_health"):
		player.reset_health()


func _on_player_died() -> void:
	if _is_respawning:
		return
	_is_respawning = true

	_show_death_overlay(true)
	await get_tree().create_timer(respawn_delay_seconds).timeout

	if is_instance_valid(player):
		if player.has_method("respawn_at"):
			player.respawn_at(respawn_position)
		else:
			player.global_position = respawn_position

	_show_death_overlay(false)
	_is_respawning = false


func _ensure_death_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.name = "DeathOverlay"
	layer.layer = 100
	add_child(layer)

	_death_overlay_rect = ColorRect.new()
	_death_overlay_rect.name = "Black"
	_death_overlay_rect.color = Color.BLACK
	_death_overlay_rect.visible = false
	_death_overlay_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_death_overlay_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_death_overlay_rect.offset_left = 0
	_death_overlay_rect.offset_top = 0
	_death_overlay_rect.offset_right = 0
	_death_overlay_rect.offset_bottom = 0
	layer.add_child(_death_overlay_rect)


func _show_death_overlay(visible: bool) -> void:
	if _death_overlay_rect:
		_death_overlay_rect.visible = visible


func _load_checkpoint_if_any() -> void:
	var config := ConfigFile.new()
	var err := config.load(SAVE_PATH)
	if err != OK:
		return
	if not config.has_section_key(SAVE_SECTION, "respawn_x"):
		return

	var x := float(config.get_value(SAVE_SECTION, "respawn_x", respawn_position.x))
	var y := float(config.get_value(SAVE_SECTION, "respawn_y", respawn_position.y))
	respawn_position = Vector2(x, y)
	player.global_position = respawn_position


func _save_checkpoint() -> void:
	var config := ConfigFile.new()
	config.set_value(SAVE_SECTION, "respawn_x", respawn_position.x)
	config.set_value(SAVE_SECTION, "respawn_y", respawn_position.y)
	config.save(SAVE_PATH)
