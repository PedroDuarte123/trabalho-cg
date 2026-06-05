extends CharacterBody2D

signal died

@onready var ray = $RayCast2D
@onready var shadow = $Shadow
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var hearts_list = get_tree().get_first_node_in_group("hearts").get_children()
@onready var lifebar = get_tree().get_first_node_in_group("lifebar")
@onready var gpu_particles_2d: GPUParticles2D = $GPUParticles2D
@onready var point_light_2d: PointLight2D = $GPUParticles2D/PointLight2D
@onready var collision_ataque: CollisionShape2D = $AreaAtaque/CollisionAtaque

var is_attacking := false
const MAX_HEALTH := 3
var health := MAX_HEALTH
var is_dead := false
const SPEED = 400.0
const JUMP_VELOCITY = -400.0
var was_on_floor := true
var is_praying = false
var invencivel := false
var moedas = 0

# --- KNOCKBACK (novo) ---
const KNOCKBACK_H:        float = 300.0
const KNOCKBACK_V:        float = -400.0
const KNOCKBACK_V_SIDE:   float = -200.0
const KNOCKBACK_DURATION: float = 0.22
const KNOCKBACK_FRICTION: float = 800.0
var _knockback_timer: float = 0.0


func _physics_process(delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# --- CONTROLE DE FRAMES DE COLISÃO EM SEGUNDO PLANO ---
	# Monitora os frames sem bloquear a física ou os comandos de andar
	if is_attacking and animated_sprite_2d.animation == "Attack":
		if animated_sprite_2d.frame in [5, 6, 7]:
			collision_ataque.disabled = false
		else:
			collision_ataque.disabled = true
	else:
		if collision_ataque:
			collision_ataque.disabled = true

	# --- GRAVIDADE ---
	if not is_on_floor():
		velocity += get_gravity() * delta

	# --- TIMERS / KNOCKBACK ---
	if _knockback_timer > 0.0:
		_knockback_timer -= delta
		velocity.x = move_toward(velocity.x, 0.0, KNOCKBACK_FRICTION * delta)
	else:
		# Pulo e drop de plataforma (Funciona mesmo atacando!)
		if is_on_floor() and Input.is_action_just_pressed("ui_accept"):
			if Input.is_action_pressed("Down"):
				position.y += 1
			else:
				velocity.y = JUMP_VELOCITY
			
		# Movimentação Horizontal (Livre para andar e virar enquanto ataca!)
		var direction := Input.get_axis("Left", "Right")
		if direction:
			velocity.x = direction * SPEED
			animated_sprite_2d.flip_h = direction < 0
			$AreaAtaque.scale.x = -1 if direction < 0 else 1
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			
	if is_praying:
		velocity = Vector2.ZERO
		move_and_slide()
		return			

	# Aplica o movimento final no mundo
	move_and_slide()

	# --- SISTEMA DE ANIMAÇÃO INTELIGENTE ---
	# Se estiver atacando, a animação de ataque tem prioridade na tela.
	# As outras animações só voltam a rodar quando o ataque terminar.
	if is_attacking:
		pass 
	elif not is_on_floor():
		if was_on_floor:
			$AnimatedSprite2D.play("Jumping")
			$AnimatedSprite2D.offset.y = 0
		was_on_floor = false
	else:
		was_on_floor = true
		var direction := Input.get_axis("Left", "Right")
		if direction != 0:
			$AnimatedSprite2D.play("Running")
			$AnimatedSprite2D.offset.y = 2
		else:
			$AnimatedSprite2D.play("Idle")
			$AnimatedSprite2D.offset.y = 0
			
	# Colisões extras com plataformas
	for platforms in get_slide_collision_count():
		var collision = get_slide_collision(platforms)
		if collision.get_collider().has_method("has_collided_with"):
			collision.get_collider().has_collided_with(collision, self)

func _process(delta):
	if ray.is_colliding():
		var hit = ray.get_collision_point()
		var normal = ray.get_collision_normal()
		
		if normal.angle_to(Vector2.UP) < deg_to_rad(45):
			shadow.global_position = Vector2(global_position.x, hit.y)
			shadow.rotation = normal.angle() + PI / 2
			shadow.visible = true
		else:
			shadow.visible = false
	else:
		shadow.visible = false

func _unhandled_input(event: InputEvent) -> void:
	# Detecta o clique esquerdo do mouse
	if event.is_action_pressed("Attack") and not is_attacking and not is_dead and not is_praying:
		ataque_player()

func ataque_player() -> void:
	is_attacking = true
	animated_sprite_2d.play("Attack")
	animated_sprite_2d.offset.y = 0 

func damage(damage_source_position: Vector2 = Vector2.ZERO) -> void:
	if is_dead:
		return
	if health <= 0:
		return
		
	if invencivel:
		return

	invencivel = true
		
	health -= 1

	# --- Knockback (novo) ---
	if damage_source_position != Vector2.ZERO:
		var dir := global_position - damage_source_position
		if abs(dir.y) > abs(dir.x):
			velocity.x = 0.0
			velocity.y = KNOCKBACK_V
		else:
			velocity.x = sign(dir.x) * KNOCKBACK_H
			velocity.y = KNOCKBACK_V_SIDE
		_knockback_timer = KNOCKBACK_DURATION

	#efeito piscar
	var tween = get_tree().create_tween()
	tween.tween_method(SetShader_BlinkIntensity, 1.0, 0.0, 0.4)
	
	#efeito particulas
	gpu_particles_2d.restart();
	gpu_particles_2d.emitting = true;
	point_light_2d.enabled = true;
	

	var life = hearts_list[health]
	life.get_node("Skull").play("damage")
	life.get_node("DamageAnimation").play("default")
	lifebar.frame = 3 - health

	if health <= 0 and not is_dead:
		is_dead = true
		emit_signal("died")
	
	#efeito luz final
	await get_tree().create_timer(gpu_particles_2d.lifetime).timeout
	point_light_2d.enabled = false;
	
	await get_tree().create_timer(0.3).timeout

	invencivel = false


func respawn_at(new_global_position: Vector2) -> void:
	global_position = new_global_position
	velocity = Vector2.ZERO
	_knockback_timer = 0.0
	reset_health()


func reset_health() -> void:
	health = MAX_HEALTH
	is_dead = false
	_update_health_ui_full()


func _update_health_ui_full() -> void:
	if lifebar:
		lifebar.frame = 0
	for life in hearts_list:
		if not life:
			continue
		var skull := life.get_node_or_null("Skull")
		if skull and skull is AnimatedSprite2D:
			if (skull as AnimatedSprite2D).sprite_frames and (skull as AnimatedSprite2D).sprite_frames.has_animation("idle"):
				(skull as AnimatedSprite2D).play("idle")
			else:
				(skull as AnimatedSprite2D).stop()
		var damage_anim := life.get_node_or_null("DamageAnimation")
		if damage_anim and damage_anim is AnimatedSprite2D:
			(damage_anim as AnimatedSprite2D).stop()
			(damage_anim as AnimatedSprite2D).frame = 0
	
func SetShader_BlinkIntensity(newValue: float):
	animated_sprite_2d.material.set_shader_parameter("blink_intensity", newValue)


func _on_animated_sprite_2d_animation_finished() -> void:
	if animated_sprite_2d.animation == "Attack":
		is_attacking = false
		collision_ataque.disabled = true # Garante que desliga a colisão após o ataque


func _on_area_ataque_body_entered(body: Node2D) -> void:
	if body.has_method("damage") and body != self:
		body.damage(1)
