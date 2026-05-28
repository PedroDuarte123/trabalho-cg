extends Node2D

@export var respawn_offset := Vector2.ZERO

@onready var area: Area2D = $Area2D

var _player_in_range := false


func _ready() -> void:
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	if not _player_in_range:
		return
	if Input.is_action_just_pressed("Interact"):
		var game := get_tree().get_first_node_in_group("game")
		if game and game.has_method("set_checkpoint"):
			game.set_checkpoint(global_position + respawn_offset)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_in_range = true


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
