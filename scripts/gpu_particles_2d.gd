extends GPUParticles2D

@onready var camera = get_viewport().get_camera_2d()

func _process(_delta: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if is_instance_valid(cam):
		global_position = cam.global_position
