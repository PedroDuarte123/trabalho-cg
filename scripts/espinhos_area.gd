extends Area2D

@onready var collision: CollisionShape2D = $collision
@onready var espinho: Sprite2D = $espinho

# Evita múltiplos danos em áreas sobrepostas apenas para o Player
var _player_atingido := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	# CASO 1: Se for o Esqueleto ou qualquer inimigo no grupo "Enemies"
	if body.is_in_group("Enemies") and body.has_method("die"):
		body.die()
		return

	# CASO 2: Se for o Player
	if body.is_in_group("player") and body.has_method("damage"):
		if _player_atingido:
			return # Ignora se o player já acabou de levar dano aqui
			
		_player_atingido = true
		body.damage(global_position)

		# Só teleporta se o dano não matou o player
		if not body.is_dead:
			var game = get_tree().get_first_node_in_group("game")
			if game and game.has_method("get_last_checkpoint"):
				await get_tree().create_timer(0.15).timeout
				if is_instance_valid(body) and not body.is_dead:
					body.global_position = game.get_last_checkpoint()
					body.velocity = Vector2.ZERO
					if game.has_method("reset_boss_arena"):
						game.reset_boss_arena()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_atingido = false
