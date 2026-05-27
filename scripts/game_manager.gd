extends Node2D

const SAVE_PATH := "user://savegame.cfg"
const SAVE_SECTION := "player"

@onready var player: CharacterBody2D = $Player

var respawn_position: Vector2
const death_screen = preload("res://scenes/deathscreen.tscn")

func _enter_tree() -> void:
	add_to_group("game")


func _ready() -> void:
	
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
	var deathS =_instantiate_death_screen()
	await deathS.finished

	if is_instance_valid(player):
		if player.has_method("respawn_at"):
			player.respawn_at(respawn_position)
		else:
			player.global_position = respawn_position


func _instantiate_death_screen():
	var deathS = death_screen.instantiate()
	get_tree().root.add_child(deathS)
	return deathS


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
