extends CharacterBody2D

# Configurações do Boss
@export var max_health: int = 20
@export var speed: float = 120.0
@export var skill_cooldown_time: float = 50.0

# Pre-carregar a cena da Alma (Lacaio) - Ajuste o caminho conforme sua pasta!
@export var soul_scene: PackedScene = preload("res://scenes/boss_soul.tscn")

var current_health: int
var player: CharacterBody2D = null
var is_dead: bool = false
var is_hurt: bool = false
var is_attacking: bool = false
var is_casting: bool = false

# Timers
var _skill_timer: float = 0.0

# Referências
@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox_ataque_shape: CollisionShape2D = $HitboxAtaque/CollisionShape2D

var _light_armor: LightArmor = null
var _stunned_by_light: bool = false
var souls_summoned: bool = false

func _ready() -> void:
	current_health = max_health
	_skill_timer = skill_cooldown_time # Começa pronto ou carregando
	_setup_boss_armor()
	
	# Conexões de Sinais das Áreas
	$AreaPerseguicao.body_entered.connect(_on_area_perseguicao_body_entered)
	$AreaPerseguicao.body_exited.connect(_on_area_perseguicao_body_exited)
	$AreaAtaqueDetect.body_entered.connect(_on_area_ataque_detect_body_entered)
	$HitboxAtaque.body_entered.connect(_on_hitbox_ataque_body_entered)
	anim_sprite.animation_finished.connect(_on_animation_finished)

func _setup_boss_armor() -> void:
	# Instancia sua classe customizada LightArmor dinamicamente
	var armor := LightArmor.new()
	armor.max_armor = 4.0 # Boss tem escudo mais forte que o esqueleto
	armor.drain_per_second = 1.0
	armor.debug_log = false
	armor.lit_changed.connect(_on_light_armor_lit_changed)
	add_child(armor)
	_light_armor = armor

func _on_light_armor_lit_changed(is_lit: bool) -> void:
	_stunned_by_light = is_lit
	if _stunned_by_light:
		is_attacking = false
		hitbox_ataque_shape.disabled = true

func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
	# Gerenciador da Skill de Recarga (50 segundos)
	if _skill_timer > 0.0:
		_skill_timer -= delta
	else:
		if not is_hurt and not is_dead and not _stunned_by_light:
			use_recharge_skill()

	if _stunned_by_light or is_hurt or is_casting:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Ataque ativo: gerencia ativação da colisão por frames específicos (ex: frames 5, 6, 7)
	if is_attacking:
		velocity = Vector2.ZERO
		if anim_sprite.animation == "Attack" and anim_sprite.frame in [5, 6, 7]:
			hitbox_ataque_shape.disabled = false
		else:
			hitbox_ataque_shape.disabled = true
		move_and_slide()
		return

	# Movimentação e Perseguição Flutuante (Sem gravidade)
	if player and not player.is_dead:
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
		anim_sprite.play("Idle")
		anim_sprite.flip_h = direction.x < 0
		
		# Ajusta as direções das áreas de colisão baseado para onde ele olha
		$HitboxAtaque.scale.x = -1 if direction.x < 0 else 1
		$AreaAtaqueDetect.scale.x = -1 if direction.x < 0 else 1
	else:
		velocity = Vector2.ZERO
		anim_sprite.play("Idle")

	move_and_slide()

# --- HABILIDADE DE RECARGA (A cada 50s) ---
func use_recharge_skill() -> void:
	is_casting = true
	velocity = Vector2.ZERO
	anim_sprite.play("Skill1")
	
	# Se a armadura foi quebrada, restaura o estado inicial dela
	if _light_armor:
		_light_armor.is_broken = false
		_light_armor.armor = _light_armor.max_armor
		if _light_armor.debug_log:
			print("[Boss] Escudo de Luz RECARREGADO por habilidade!")
			
	_skill_timer = skill_cooldown_time

# --- RECEBER DANOS E MORTE ---
func damage(amount: int = 1, damage_source_position: Vector2 = Vector2.ZERO) -> void:
	if is_dead or is_hurt:
		return
	if _light_armor != null and not _light_armor.is_broken:
		# Se tiver escudo de luz intacto, ele absorve todo o dano
		return

	current_health -= amount
	
	# Condição de invocação de Almas (Metade da Vida: 10 HP)
	if current_health <= 10 and not souls_summoned:
		summon_souls()

	if current_health <= 0:
		die()
	else:
		if anim_sprite.sprite_frames.has_animation("Hurt"):
			is_hurt = true
			is_attacking = false
			hitbox_ataque_shape.disabled = true
			anim_sprite.play("Hurt")

func summon_souls() -> void:
	souls_summoned = true
	# Invoca 3 pequenas almas ao redor do boss
	for i in range(3):
		if soul_scene:
			var soul = soul_scene.instantiate()
			# Adiciona um pequeno offset para não nascerem grudadas
			soul.global_position = global_position + Vector2(randf_range(-50, 50), randf_range(-50, 50))
			get_tree().current_scene.add_child(soul)

func die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	hitbox_ataque_shape.set_deferred("disabled", true)
	$CollisionShape2D.set_deferred("disabled", true)
	
	if anim_sprite.sprite_frames.has_animation("Death"):
		anim_sprite.play("Death")
	else:
		queue_free()

# --- SINAIS DAS ÁREAS ---
func _on_area_perseguicao_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name.to_lower() == "player":
		player = body

func _on_area_perseguicao_body_exited(body: Node2D) -> void:
	if body == player:
		player = null

func _on_area_ataque_detect_body_entered(body: Node2D) -> void:
	if (body.is_in_group("player") or body.name.to_lower() == "player") and not is_attacking and not is_hurt and not _stunned_by_light:
		is_attacking = true
		anim_sprite.play("Attack")

func _on_hitbox_ataque_body_entered(body: Node2D) -> void:
	if body.has_method("damage") and not is_dead:
		# Dá dano no Player e passa a posição do Boss para aplicar o Knockback que está no seu Player.gd
		body.damage(global_position)

func _on_animation_finished() -> void:
	if anim_sprite.animation == "Attack":
		is_attacking = false
		hitbox_ataque_shape.disabled = true
	elif anim_sprite.animation == "Hurt":
		is_hurt = false
	elif anim_sprite.animation == "Cast":
		is_casting = false
	elif anim_sprite.animation == "Die":
		queue_free()
