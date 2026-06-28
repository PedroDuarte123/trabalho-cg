extends CharacterBody2D

@export var speed: float = 90.0
@export var damage_amount: int = 1

var health: int = 1
var player: CharacterBody2D = null
var is_dead: bool = false

@onready var hit_zone: Area2D = $Area2D # Certifique-se de ter uma Area2D na cena da Alma

func _ready() -> void:
	# Procura o jogador automaticamente se ele estiver no grupo "player"
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		
	hit_zone.body_entered.connect(_on_body_entered)


func _physics_process(_delta: float) -> void:
	if is_dead:
		return
		
	if player and not player.is_dead:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
		
		# Inversão visual simples se a alma tiver sprite direcional
		if has_node("Sprite2D"):
			$Sprite2D.flip_h = direction.x < 0
	else:
		velocity = Vector2.ZERO
		
	move_and_slide()


# Função para receber dano (chamada pela espada/ataque do jogador)
func damage(amount: int = 1, _source_pos: Vector2 = Vector2.ZERO) -> void:
	if is_dead:
		return
		
	health -= amount
	if health <= 0:
		die()


func die() -> void:
	is_dead = true
	# Se tiver uma animação ou efeito de sumiço, coloque aqui antes do queue_free
	queue_free()


func _on_body_entered(body: Node2D) -> void:
	if is_dead:
		return
		
	if body.is_in_group("player") or body.is_in_group("Player"):
		if body.has_method("damage"):
			body.damage(global_position)
			die() # A alma se destrói ao explodir/tocar no player
