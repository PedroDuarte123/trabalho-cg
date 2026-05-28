extends CharacterBody2D

# Configurações do Inimigo
@export var speed: float = 50.0
@export var max_health: int = 2
var current_health: int

# Variáveis de Controle
var direction: int = 1 # 1 para direita, -1 para esquerda
var is_attacking: bool = false
var is_dead: bool = false

# Gravidade (pega a configuração padrão do projeto)
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Referências aos Nós
@onready var anim_sprite = $AnimatedSprite2D
@onready var wall_raycast = $WallRayCast2D
@onready var player_raycast = $PlayerRayCast2D
@onready var hitbox_espada_shape = $AreaDanoEspada/CollisionShape2D




func _ready():
	current_health = max_health
	$AreaDanoEspada.body_entered.connect(_on_area_dano_espada_body_entered)


func _physics_process(delta):
	if is_dead:
		return
		
	# Aplicar gravidade
	if not is_on_floor():
		velocity.y += gravity * delta

	# Se estiver atacando, não anda
	if is_attacking:
		velocity.x = 0
		
		# CONTROLE DO FRAME DE DANO:
		# Só ativa a colisão se estiver na animação "Attack" E exatamente no frame 5
		if anim_sprite.animation == "Attack" and anim_sprite.frame == 5:
			hitbox_espada_shape.disabled = false
		else:
			hitbox_espada_shape.disabled = true
			
		if not anim_sprite.is_playing() or anim_sprite.animation != "Attack":
			is_attacking = false
	else:
		# Se não estiver atacando, garante que a hitbox está desligada
		hitbox_espada_shape.disabled = true
		_patrol_state()
		_check_for_player()

	move_and_slide()


func _patrol_state():
	# Verifica se o raio da parede bateu em algo
	if wall_raycast.is_colliding():
		var collider = wall_raycast.get_collider()
		
		# Só inverte a direção se o objeto NÃO estiver no grupo "Player"
		if collider != null and not collider.is_in_group("Player"):
			_flip_direction()

	velocity.x = direction * speed
	anim_sprite.play("Walk")
	
	
func _flip_direction():
	direction *= -1
	anim_sprite.flip_h = direction < 0
	wall_raycast.target_position.x *= -1
	player_raycast.target_position.x *= -1
	
	# Move a área do dano para frente ou para trás do esqueleto dependendo do lado que ele olha
	hitbox_espada_shape.position.x *= -1


# O SINAL DE COLISÃO (Igual ao seu danoplaceholder, chamando a sua função damage())
func _on_area_dano_espada_body_entered(body):
	if body.is_in_group("player") and not is_dead:
		if body.has_method("damage"):
			body.damage(global_position) # Chama a sua função que pisca o player e atualiza os corações


func _check_for_player():
	if player_raycast.is_colliding():
		var collider = player_raycast.get_collider()
		
		# Verifica se o objeto detectado está no grupo "Player"
		# Dica: Vá na cena do seu Personagem Jogável, clique em "Node" -> "Groups" e adicione "Player"
		if collider != null and collider.is_in_group("Player"):
			is_attacking = true
			anim_sprite.play("Attack")
			
			# Lógica extra: causar dano ao player
			# if collider.has_method("take_damage"):
			#     collider.take_damage(1)

# Função para receber dano (chame esta função a partir do ataque do seu jogador)
func take_damage(amount: int = 1):
	if is_dead:
		return
		
	current_health -= amount
	
	if current_health <= 0:
		die()
	else:
		# Toca uma animação de sofrer dano (se houver) para dar feedback visual
		if anim_sprite.sprite_frames.has_animation("Hurt"):
			anim_sprite.play("Hurt")

func die():
	is_dead = true
	velocity.x = 0
	
	if anim_sprite.sprite_frames.has_animation("Die"):
		anim_sprite.play("Die")
	
	# Desativa a colisão física para o jogador poder passar por cima
	$CollisionShape2D.set_deferred("disabled", true)
	
	# Aguarda a animação de morte terminar e destrói o inimigo
	await anim_sprite.animation_finished
	queue_free()
