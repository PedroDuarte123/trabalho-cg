extends Area2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_body_entered(body: Node2D) -> void:
	$AnimatedSprite2D.play("collect")
	await get_tree().create_timer(0.2).timeout
	if body.is_in_group("player"):
		body.moedas += 1
	queue_free() # Replace with function body.
