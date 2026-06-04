extends Node2D

var _player_in_range := false
@onready var portal: Node2D = $"."

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not _player_in_range:
		return
	if Input.is_action_just_pressed("Interact"):
		var player = get_tree().get_first_node_in_group("player")
		$PortalAnimation.play("default")
		player.set_physics_process(false)
		await get_tree().create_timer(0.8).timeout
		
		player.visible = false
		
		await get_tree().create_timer(1.0).timeout
		
		var tween = create_tween()
		tween.tween_property(portal, "modulate:a", 0.0, 0.3)
		await tween.finished
		
		portal.visible = false
		

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
