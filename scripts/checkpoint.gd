extends Node2D

@export var respawn_offset := Vector2.ZERO

@onready var area: Area2D = $Area2D


var _player_in_range := false
var _interacting := false

func _ready() -> void:
	$AnimatedSprite2D.visible = false
	$Key.visible = false
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)


func _process(_delta: float) -> void:
	if not _player_in_range:
		return
	if _interacting:
		return	
	if Input.is_action_just_pressed("Interact"):
		_interacting = true
		var player = get_tree().get_first_node_in_group("player")
		player.is_praying = true
		
		$AnimatedSprite2D.modulate.a = 0.0
		$AnimatedSprite2D/PointLight2D.energy = 0.0
		$AnimatedSprite2D.visible = true
		
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property($AnimatedSprite2D, "modulate:a", 1.0, 0.4)
		tween.tween_property($AnimatedSprite2D/PointLight2D, "energy", 10.0, 0.4)
		
		player.get_node("AnimatedSprite2D").play("Pray")
		await player.get_node("AnimatedSprite2D").animation_finished
		player.is_praying = false
		
		var game := get_tree().get_first_node_in_group("game")
		if game and game.has_method("set_checkpoint"):
			game.set_checkpoint(global_position + respawn_offset)
			
		_interacting = false


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_in_range = true
		$Key.visible = true
		var tween = create_tween()
		tween.tween_property($Key, "modulate:a", 1.0, 0.3).from(0.0)



func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
		var tween = create_tween()
		tween.tween_property($Key, "modulate:a", 0.0, 0.3).from(1.0)
		await tween.finished
		$Key.visible = false
