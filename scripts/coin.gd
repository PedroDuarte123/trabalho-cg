extends Area2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animated_sprite_2d.frame_changed.connect(_on_frame_changed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_body_entered(body: Node2D) -> void:
	$AnimatedSprite2D.play("collect")
	await get_tree().create_timer(0.2).timeout
	if body.is_in_group("player"):
		body.moedas += 1
	queue_free() # Replace with function body.
	
func _on_frame_changed():
	if animated_sprite_2d.frame >= 5 and animated_sprite_2d.frame <= 8:
		animated_sprite_2d.modulate = Color(2.5, 2.5, 2.5, 1.0)
	else:
		animated_sprite_2d.modulate = Color.WHITE
