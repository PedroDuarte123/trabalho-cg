extends Area2D

# Arraste o arquivo .tscn do elemento que quer sumonar para cá no Inspetor
@export var cena_para_sumonar: PackedScene 

@onready var painel_pergunta = $CanvasLayer/Panel
@onready var botao_certo = $CanvasLayer/Panel/Button
@onready var botao_errado = $CanvasLayer/Panel/Button2

var player_no_alcance = false
var player_ref = null

func _ready():
	# Conecta os botões via código (ou faça pelo editor)
	botao_certo.pressed.connect(_on_resposta_certa)
	botao_errado.pressed.connect(_on_resposta_errada)

func _process(_delta):
	# Se o player estiver perto e apertar "E" (ou a tecla de interação que configurou)
	if player_no_alcance and Input.is_action_just_pressed("ui_accept"): 
		abrir_pergunta()

func _on_body_entered(body):
	if body.is_in_group("Player"): # Certifique-se de que seu Player está no grupo "Player"
		player_no_alcance = true
		player_ref = body

func _on_body_exited(body):
	if body.is_in_group("Player"):
		player_no_alcance = false
		fechar_pergunta()

func abrir_pergunta():
	painel_pergunta.visible = true
	# Opcional: pausar o jogo ou travar o movimento do player aqui

func fechar_pergunta():
	painel_pergunta.visible = false

func _on_resposta_certa():
	print("Acertou!")
	fechar_pergunta()
	sumonar_elemento()
	queue_free() # Destrói o totem após responder certo (opcional)

func _on_resposta_errada():
	print("Errou!")
	if player_ref and player_ref.has_method("receber_dano"):
		player_ref.receber_dano(10) # Aplica 10 de dano no player
	fechar_pergunta()

func sumonar_elemento():
	if cena_para_sumonar:
		var instancia = cena_para_sumonar.instantiate()
		# Define a posição do novo elemento para a mesma do totem
		instancia.global_position = global_position 
		# Adiciona o elemento na cena principal (no pai do totem)
		get_parent().add_child(instancia)
