extends CharacterBody2D

@onready var ray = $RayCast2D
@onready var shadow = $Shadow
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var hearts_list = get_tree().get_first_node_in_group("hearts").get_children()
@onready var lifebar = get_tree().get_first_node_in_group("lifebar")
@onready var gpu_particles_2d: GPUParticles2D = $GPUParticles2D
@onready var point_light_2d: PointLight2D = $GPUParticles2D/PointLight2D

var health = 3
const SPEED = 400.0
const JUMP_VELOCITY = -400.0
var was_on_floor := true

func _physics_process(delta: float) -> void:

	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
		
	if is_on_floor() and Input.is_action_just_pressed("ui_accept"):
		if Input.is_action_pressed("Down"):
			position.y += 1
		else:
			velocity.y = JUMP_VELOCITY
		
	# Movement
	var direction := Input.get_axis("Left", "Right")
	if direction:
		velocity.x = direction * SPEED
		$AnimatedSprite2D.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

	# Animação
	if not is_on_floor():
		if was_on_floor:  # só chama play UMA vez, no momento que sai do chão
			$AnimatedSprite2D.play("Jumping")
			$AnimatedSprite2D.offset.y = 0
		was_on_floor = false
	else:
		was_on_floor = true
		if direction != 0:
			$AnimatedSprite2D.play("Running")
			$AnimatedSprite2D.offset.y = 2
		else:
			$AnimatedSprite2D.play("Idle")
			$AnimatedSprite2D.offset.y = 0

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
		
func damage() -> void:
	
	
	#if health <= 0:
		#return
		
	health -= 1
	
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
	
	#efeito luz final
	await get_tree().create_timer(gpu_particles_2d.lifetime).timeout
	point_light_2d.enabled = false;
	
func SetShader_BlinkIntensity(newValue: float):
	animated_sprite_2d.material.set_shader_parameter("blink_intensity", newValue)
	
	
		

	
