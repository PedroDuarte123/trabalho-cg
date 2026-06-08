extends CharacterBody2D

@export_group("Light Armor")
@export var has_light_armor: bool = true
@export_range(0.1, 999.0, 0.1) var light_armor_max: float = 3.0
@export_range(0.0, 999.0, 0.1) var light_armor_drain_per_second: float = 1.2
@export var light_armor_debug_log: bool = false
@export_range(0.05, 10.0, 0.05) var light_armor_debug_interval: float = 0.5
@onready var gpu_particles_2d: GPUParticles2D = $GPUParticles2D



# Configurações do Inimigo
@export var speed: float = 50.0
@export var max_health: int = 2
var current_health: int

# Variáveis de Controle
var direction: int = 1 # 1 para direita, -1 para esquerda
var is_attacking: bool = false
var is_dead: bool = false
var is_hurt: bool = false

# Gravidade (pega a configuração padrão do projeto)
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Referências aos Nós
@onready var anim_sprite = $AnimatedSprite2D
@onready var wall_raycast = $WallRayCast2D
@onready var player_raycast = $PlayerRayCast2D
@onready var cliff_raycast = $CliffRayCast2D
@onready var hitbox_espada_shape = $AreaDanoEspada/CollisionShape2D

var _light_armor: LightArmor = null
var _stunned_by_light: bool = false




func _ready():
	current_health = max_health
	_setup_light_armor()
	$AreaDanoEspada.body_entered.connect(_on_area_dano_espada_body_entered)


func _setup_light_armor() -> void:
	if not has_light_armor:
		return

	var armor := LightArmor.new()
	armor.max_armor = light_armor_max
	armor.drain_per_second = light_armor_drain_per_second
	armor.debug_log = light_armor_debug_log
	armor.debug_log_interval = light_armor_debug_interval
	armor.lit_changed.connect(_on_light_armor_lit_changed)
	add_child(armor)
	_light_armor = armor


func _on_light_armor_lit_changed(is_lit: bool) -> void:
	# Enquanto estiver iluminado, o esqueleto fica parado.
	_stunned_by_light = is_lit
	if _stunned_by_light:
		is_attacking = false
		hitbox_espada_shape.disabled = true


func _physics_process(delta):
	if is_dead:
		return

	if _stunned_by_light:
		# Ainda aplica gravidade, mas não patrulha nem ataca.
		if not is_on_floor():
			velocity.y += gravity * delta
		velocity.x = 0
		move_and_slide()
		return
	
	if is_hurt:
		if not is_on_floor():
			velocity.y += gravity * delta
		velocity.x = 0
		move_and_slide()
		return # Impede de patrulhar ou atacar enquanto sofre dano
	
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
	
	if not cliff_raycast.is_colliding():
		var collider = cliff_raycast.get_collider()
		
		# Só inverte a direção se o "cliff_raycast" nao estiver colidindo com nada do ambiente
		_flip_direction()
	
	velocity.x = direction * speed
	anim_sprite.play("Walk")
	
	
func _flip_direction():
	direction *= -1
	anim_sprite.flip_h = direction < 0
	wall_raycast.target_position.x *= -1
	player_raycast.target_position.x *= -1
	cliff_raycast.position.x *= -1
	
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
func damage(amount: int = 1):
	if is_dead or is_hurt:
		return
	if _light_armor != null and _light_armor.is_intact():
		return
		
	current_health -= amount
	
	if current_health <= 0:
		die()
	else:
		# Toca uma animação de sofrer dano (se houver) para dar feedback visual
		if anim_sprite.sprite_frames.has_animation("Hurt"):
			is_hurt = true
			velocity.x = 0 # Para o movimento imediatamente
			anim_sprite.play("Hurt")
			gpu_particles_2d.restart();
			gpu_particles_2d.emitting = true;
			
			# Espera a animação "Hurt" terminar antes de voltar a patrulhar
			await anim_sprite.animation_finished
			is_hurt = false

func die():
	is_dead = true
	velocity.x = 0
	
	if anim_sprite.sprite_frames.has_animation("Die"):
		anim_sprite.play("Die")
		gpu_particles_2d.restart();
		gpu_particles_2d.emitting = true;
	
	# Desativa a colisão física para o jogador poder passar por cima
	$CollisionShape2D.set_deferred("disabled", true)
	
	# Aguarda a animação de morte terminar e destrói o inimigo
	await anim_sprite.animation_finished
	queue_free()
