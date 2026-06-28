extends CharacterBody2D

@export var max_health: int = 20
@export var speed: float = 120.0
@export var skill_cooldown_time: float = 50.0
@export var soul_scene: PackedScene = preload("res://scenes/boss_soul.tscn")


var current_health: int
var player: CharacterBody2D = null
var is_dead: bool = false
var is_hurt: bool = false
var is_attacking: bool = false
var is_casting: bool = false

var _skill_timer: float = 0.0

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox_ataque_shape: CollisionShape2D = $HitboxAtaque/CollisionShape2D

var _light_armor: LightArmor = null
var _stunned_by_light: bool = false
var souls_summoned: bool = false


func _ready() -> void:
	current_health = max_health
	_skill_timer = skill_cooldown_time
	_setup_boss_armor()

	# Começa nulo para a ArenaBoss ativar depois
	player = null

	# Use apenas o nome direto do nó filho:
	$AreaAtaqueDetect.body_entered.connect(_on_area_ataque_detect_body_entered)
	$HitboxAtaque.body_entered.connect(_on_hitbox_ataque_body_entered)
	
	anim_sprite.animation_finished.connect(_on_animation_finished)

func _setup_boss_armor() -> void:
	# Se você não tiver o nó "ShieldBrokenEffect" na cena do Boss, criamos um visível
	# Mas em vez de vazio, vamos fazer o próprio corpo do Boss piscar azul/branco quando quebrar
	var armor := LightArmor.new()
	armor.max_armor = 4.0
	armor.drain_per_second = 1.0
	armor.debug_log = false
	armor.lit_changed.connect(_on_light_armor_lit_changed)
	
	# Conecta o sinal de quebra de armadura para fazer um efeito visual direto no Boss
	armor.armor_broken.connect(_on_boss_armor_broken)
	
	add_child(armor)
	_light_armor = armor

# --- NOVA FUNÇÃO DE FEEDBACK DE QUEBRA DE ESCUDO ---
func _on_boss_armor_broken() -> void:
	# Como o ShieldBrokenEffect do script original pode estar ausente ou nulo,
	# geramos um flash de luz modulando a cor do próprio Boss para dar o feedback visual
	var tween = create_tween()
	tween.tween_property(anim_sprite, "modulate", Color(0, 2, 2, 1), 0.1) # Brilho ciano/azul
	tween.tween_property(anim_sprite, "modulate", Color(1, 1, 1, 1), 0.15) # Volta ao normal
	print("[Boss] Escudo de luz estilhaçado!")


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
		if not is_hurt and not is_dead:
			use_recharge_skill()

	if is_hurt or is_casting:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# --- CONTROLE DOS FRAMES EXATOS DE ATAQUE ---
	if is_attacking:
		# Ativa a colisão apenas se estiver na animação "Attack" E nos frames específicos: 2, 3, 9 ou 10
		if anim_sprite.animation == "Attack" and anim_sprite.frame in [2, 3, 9, 10]:
			hitbox_ataque_shape.disabled = false
		else:
			hitbox_ataque_shape.disabled = true
	else:
		# Garante que a hitbox fica desligada se não estiver atacando
		hitbox_ataque_shape.disabled = true

	# Movimentação e Perseguição Flutuante Implacável
	if player and not player.is_dead:
		var direction = (player.global_position - global_position).normalized()
		
		# Se estiver sob a lanterna (_stunned_by_light), ele fica ligeiramente mais lento (40% da velocidade)
		var velocidade_atual = speed * 0.4 if _stunned_by_light else speed
		velocity = direction * velocidade_atual
		
		# Só toca a animação de movimento se não estiver executando a de Ataque
		if not is_attacking:
			anim_sprite.play("Idle")
			
		# --- INVERSÃO DO SPRITE DO BOSS ---
		if direction.x < 0:
			anim_sprite.flip_h = true
		elif direction.x > 0:
			anim_sprite.flip_h = false
	else:
		velocity = Vector2.ZERO
		if not is_attacking:
			anim_sprite.play("Idle")

	move_and_slide()

func use_recharge_skill() -> void:
	is_casting = true
	velocity = Vector2.ZERO
	anim_sprite.play("Skill1")

	if _light_armor:
		_light_armor.is_broken = false
		_light_armor.armor = _light_armor.max_armor

	_skill_timer = skill_cooldown_time


func damage(amount: int = 1, damage_source_position: Vector2 = Vector2.ZERO) -> void:
	if is_dead or is_hurt:
		return

	if _light_armor != null and not _light_armor.is_broken:
		return

	current_health -= amount

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

	for i in range(3):
		if soul_scene:
			var soul = soul_scene.instantiate()
			soul.global_position = global_position + Vector2(randf_range(-50, 50), randf_range(-50, 50))
			get_tree().current_scene.add_child(soul)


func die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	hitbox_ataque_shape.set_deferred("disabled", true)
	$CollisionShape2D.set_deferred("disabled", true)
	
	# Procura o nó da Arena na árvore e libera o jogador e a câmera
	var arena = get_tree().current_scene.find_child("ArenaBoss", true, false)
	if arena and arena.has_method("encerrar_arena"):
		arena.encerrar_arena()
		
	if anim_sprite.sprite_frames.has_animation("Die"):
		anim_sprite.play("Die")
	else:
		queue_free()


func _on_area_ataque_detect_body_entered(body: Node2D) -> void:
	if (body.is_in_group("Player") or body.is_in_group("player")) and not is_attacking and not is_hurt and not _stunned_by_light:
		is_attacking = true
		anim_sprite.play("Attack")


func _on_hitbox_ataque_body_entered(body: Node2D) -> void:
	if body.has_method("damage") and not is_dead:
		body.damage(global_position)


func _on_animation_finished() -> void:
	if anim_sprite.animation == "Attack":
		is_attacking = false
		hitbox_ataque_shape.disabled = true
	elif anim_sprite.animation == "Hurt":
		is_hurt = false
	elif anim_sprite.animation == "Skill1":
		is_casting = false
	elif anim_sprite.animation == "Death":
		queue_free()
