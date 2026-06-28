extends Node2D

@export var next_scene_path: String = "res://scenes/Fase2.tscn"

var _player_in_range := false
var _is_transitioning := false

@onready var portal: Node2D = $"."

func _process(delta: float) -> void:
	if not _player_in_range or _is_transitioning:
		return

	if Input.is_action_just_pressed("Interact"):
		_is_transitioning = true

		var player = get_tree().get_first_node_in_group("player")
		$PortalAnimation.play("default")

		if player:
			player.set_physics_process(false)

		await get_tree().create_timer(0.8).timeout

		if player:
			player.visible = false

		await get_tree().create_timer(1.0).timeout

		var tween = create_tween()
		tween.tween_property(portal, "modulate:a", 0.0, 0.3)
		await tween.finished

		get_tree().change_scene_to_file(next_scene_path)

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = true
		$Key.visible = true
		var tween = create_tween()
		tween.tween_property($Key, "modulate:a", 1.0, 0.3).from(0.0)

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
		var tween = create_tween()
		tween.tween_property($Key, "modulate:a", 0.0, 0.3).from(1.0)
		await tween.finished
		$Key.visible = false
