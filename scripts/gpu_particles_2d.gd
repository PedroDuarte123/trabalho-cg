extends GPUParticles2D

@onready var camera = get_viewport().get_camera_2d()

func _process(delta):
	global_position = camera.global_position
