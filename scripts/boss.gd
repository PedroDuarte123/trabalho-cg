extends CharacterBody2D

@export var max_health: int = 10 
@export var speed: float = 120.0
@export var skill_cooldown_time: float = 20.0 
@export var soul_scene: PackedScene = preload("res://scenes/boss_soul.tscn")
@export var attack_cooldown_time: float = 4.0

@export_group("Light Armor")
@export_range(0.1, 999.0, 0.1) var light_armor_max: float = 5.0
@export_range(0.0, 999.0, 0.1) var light_armor_drain_per_second: float = 1.0
@export var light_armor_debug_log: bool = true

# --- CONFIGURAÇÕES DE KNOCKBACK ---
const KNOCKBACK_H: float = 120.0
const KNOCKBACK_V: float = -75.0      
const KNOCKBACK_DURATION: float = 0.20 
var _knockback_timer: float = 0.0

var current_health: int
var player: CharacterBody2D = null
var is_dead: bool = false
var is_hurt: bool = false
var is_attacking: bool = false
var is_casting: bool = false

var _skill_timer: float = 0.0
var _attack_cooldown_timer: float = 0.0

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox_ataque_shape: CollisionShape2D = $HitboxAtaque/CollisionShape2D

# --- REFERÊNCIAS PARA INVERSÃO DE DIREÇÃO ---
@onready var area_ataque_detect: Area2D = $AreaAtaqueDetect
@onready var hitbox_ataque: Area2D = $HitboxAtaque

var _light_armor: LightArmor = null
var _stunned_by_light: bool = false
var souls_summoned: bool = false


func _ready() -> void:
	current_health = max_health
	_skill_timer = skill_cooldown_time
	_setup_boss_armor()

	player = null

	$AreaAtaqueDetect.body_entered.connect(_on_area_ataque_detect_body_entered)
	$HitboxAtaque.body_entered.connect(_on_hitbox_ataque_body_entered)
	
	anim_sprite.animation_finished.connect(_on_animation_finished)


func _setup_boss_armor() -> void:
	var armor := LightArmor.new()
	armor.max_armor = light_armor_max
	armor.drain_per_second = light_armor_drain_per_second
	armor.debug_log = light_armor_debug_log
	armor.lit_changed.connect(_on_light_armor_lit_changed)
	armor.armor_broken.connect(_on_boss_armor_broken)
	
	add_child(armor)
	_light_armor = armor


func _on_boss_armor_broken() -> void:
	var tween = create_tween()
	tween.tween_property(anim_sprite, "modulate", Color(0, 2, 2, 1), 0.1)
	tween.tween_property(anim_sprite, "modulate", Color(1, 1, 1, 1), 0.15)
	print("[Boss] Escudo de luz estilhaçado!")


func _on_light_armor_lit_changed(is_lit: bool) -> void:
	_stunned_by_light = is_lit
	if _stunned_by_light:
		is_attacking = false
		hitbox_ataque_shape.disabled = true
		if anim_sprite.animation == "Attack":
			anim_sprite.play("Idle")


func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
	if _skill_timer > 0.0:
		_skill_timer -= delta
	else:
		if not is_hurt and not is_dead and not _stunned_by_light:
			use_recharge_skill()

	if _attack_cooldown_timer > 0.0:
		_attack_cooldown_timer -= delta

	if _knockback_timer > 0.0:
		_knockback_timer -= delta
		move_and_slide()
		return

	if is_hurt or is_casting:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if _stunned_by_light:
		velocity = Vector2.ZERO
		if not is_hurt and not is_casting:
			anim_sprite.play("Idle")
		move_and_slide()
		return

	# CORREÇÃO: Removidos os colchetes daqui. Agora usa checagem direta frame a frame
	if is_attacking:
		var f := anim_sprite.frame
		if anim_sprite.animation == "Attack" and (f == 2 or f == 3 or f == 9 or f == 10):
			hitbox_ataque_shape.disabled = false
		else:
			hitbox_ataque_shape.disabled = true
	else:
		hitbox_ataque_shape.disabled = true

	if player and not player.is_dead:
		var distance_to_player = global_position.distance_to(player.global_position)
		var direction = (player.global_position - global_position).normalized()
		
		if distance_to_player > 50.0:
			velocity = direction * speed
		else:
			velocity = Vector2.ZERO
		
		if not is_attacking:
			anim_sprite.play("Idle")
			
		if direction.x < 0:
			anim_sprite.flip_h = true
			area_ataque_detect.scale.x = -1
			hitbox_ataque.scale.x = -1
		elif direction.x > 0:
			anim_sprite.flip_h = false
			area_ataque_detect.scale.x = 1
			hitbox_ataque.scale.x = 1
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

	if current_health <= 5 and not souls_summoned:
		summon_souls()
		anim_sprite.play("Summon")

	if current_health <= 0:
		die()
	else:
		if damage_source_position != Vector2.ZERO:
			var dir := global_position - damage_source_position
			velocity.x = sign(dir.x) * KNOCKBACK_H
			velocity.y = KNOCKBACK_V
			_knockback_timer = KNOCKBACK_DURATION


func summon_souls() -> void:
	souls_summoned = true
	
	# Usando atribuição direta sem loops de array complexos
	if soul_scene:
		var s1 = soul_scene.instantiate()
		s1.global_position = global_position + Vector2(0, -60)
		get_tree().current_scene.add_child(s1)
		
		var s2 = soul_scene.instantiate()
		s2.global_position = global_position + Vector2(-60, 0)
		get_tree().current_scene.add_child(s2)
		
		var s3 = soul_scene.instantiate()
		s3.global_position = global_position + Vector2(60, 0)
		get_tree().current_scene.add_child(s3)


func die() -> void:
	if is_dead:
		return
	is_dead = true
	velocity = Vector2.ZERO
	
	hitbox_ataque_shape.set_deferred("disabled", true)
	if has_node("CollisionShape2D"):
		$CollisionShape2D.set_deferred("disabled", true)
	
	if is_instance_valid(_light_armor):
		_light_armor.queue_free()
	
	var arena = get_tree().current_scene.find_child("ArenaBoss", true, false)
	if arena and arena.has_method("encerrar_arena"):
		arena.encerrar_arena()
		
	anim_sprite.play("Death")


func _on_area_ataque_detect_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") or body.is_in_group("player"):
		player = body as CharacterBody2D
		
		if not is_attacking and not is_hurt and not _stunned_by_light and _attack_cooldown_timer <= 0.0:
			is_attacking = true
			anim_sprite.play("Attack")


func _on_hitbox_ataque_body_entered(body: Node2D) -> void:
	if body.has_method("damage") and not is_dead:
		body.damage(global_position)


func _on_animation_finished() -> void:
	if anim_sprite.animation == "Attack":
		is_attacking = false
		hitbox_ataque_shape.disabled = true
		_attack_cooldown_timer = attack_cooldown_time
	elif anim_sprite.animation == "Skill1":
		is_casting = false
	elif anim_sprite.animation == "Death":
		call_deferred("queue_free")
