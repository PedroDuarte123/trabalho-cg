extends Area2D

@export var camera_zoom_arena: Vector2 = Vector2(0.7, 0.7) # Zoom mais distante para ver o boss todo
@export var boss_node: CharacterBody2D = null # Arraste o seu Boss para cá no Inspetor

var _camera_original_zoom: Vector2
var _camera: Camera2D = null
var _player: CharacterBody2D = null
var _arena_ativa: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Garante que as paredes começam invisíveis e transitáveis
	_alternar_paredes(false)

func _on_body_entered(body: Node2D) -> void:
	if _arena_ativa:
		return
		
	if body.is_in_group("player") or body.name.to_lower() == "player":
		_player = body
		_arena_ativa = true
		
		# Ativa as paredes invisíveis para prender o jogador
		_alternar_paredes(true)
		
		# Captura a câmera que está seguindo o Player
		_camera = _player.get_node_or_null("Camera2D")
		if _camera:
			_camera_original_zoom = _camera.zoom
			var tween = create_tween().set_parallel(true)
			tween.tween_property(_camera, "zoom", camera_zoom_arena, 1.0)
			_camera.top_level = true
			tween.tween_property(_camera, "global_position", global_position, 1.0)
		
		# --- BUSCA AUTOMÁTICA DO BOSS CONTRA ERROS NO INSPETOR ---
		if boss_node == null:
			# Procura na cena atual por um nó que tenha o script do Boss
			boss_node = get_tree().current_scene.find_child("Boss", true, false)
			# Se o nome do seu boss na árvore for diferente (ex: "BossInimigo"), mude o texto "Boss" acima
		
		# Injeta o player diretamente no Boss para ligar a perseguição
		if boss_node and "player" in boss_node:
			boss_node.player = _player
			print("[Arena] Jogador detectado! Boss ativado e perseguindo.")
		else:
			print("[ERRO Arena] Não foi possível encontrar o nó do Boss para ativar a perseguição!")

func _alternar_paredes(ativar: bool) -> void:
	# Percorre os filhos procurando as paredes estáticas e liga/desliga a física delas
	for child in get_children():
		if child is StaticBody2D:
			for shape in child.get_children():
				if shape is CollisionShape2D:
					shape.set_deferred("disabled", not ativar)

# Chame essa função no script do Boss quando ele morrer: get_node("../ArenaBoss").encerrar_arena()
func encerrar_arena() -> void:
	_alternar_paredes(false)
	if _camera and is_instance_valid(_camera):
		var tween = create_tween().set_parallel(true)
		tween.tween_property(_camera, "zoom", _camera_original_zoom, 1.0)
		# Devolve o controle da câmera ao player
		_camera.top_level = false
		_camera.position = Vector2.ZERO
