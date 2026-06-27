extends CharacterBody2D

@export var speed: float = 160.0 # Elas são ligeiramente mais rápidas que o Boss
var health: int = 1
var player: CharacterBody2D = null
var is_dead: bool = false

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	# Busca o player diretamente pelo grupo ou árvore para começar a caçada imediatamente
	player = get_tree().get_first_node_in_group("player")
	if not player:
		player = get_tree().current_scene.find_child("Player")
		
	$AreaDanoContato.body_entered.connect(_on_area_dano_contato_body_entered)

func _physics_process(_delta: float) -> void:
	if is_dead:
		return

	if player and not player.is_dead:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
		if anim_sprite:
			anim_sprite.play("Move")
			anim_sprite.flip_h = direction.x < 0
	else:
		velocity = Vector2.ZERO

	move_and_slide()

func damage(amount: int = 1, _source_position: Vector2 = Vector2.ZERO) -> void:
	health -= amount
	if health <= 0:
		die()

func _on_area_dano_contato_body_entered(body: Node2D) -> void:
	# Ao tocar no player, causa o dano e se destrói (estilo criatura suicida)
	if body.has_method("damage") and (body.is_in_group("player") or body.name.to_lower() == "player"):
		body.damage(global_position)
		die()

func die() -> void:
	is_dead = true
	queue_free()
