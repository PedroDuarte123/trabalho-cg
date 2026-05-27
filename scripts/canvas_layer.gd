# death_screen.gd
extends CanvasLayer

@onready var video: VideoStreamPlayer = $VideoStreamPlayer

func _ready():
	video.stream = preload("res://UI/death.ogv")
	video.modulate.a = 0.0
	video.play()
	var tween = create_tween()
	tween.tween_property(video, "modulate:a", 1.0, 0.5)
	video.finished.connect(_on_finished)

func _on_finished():
	var tween = create_tween()
	tween.tween_property($VideoStreamPlayer, "modulate:a", 0.0, 0.5)
	await tween.finished
	queue_free()
