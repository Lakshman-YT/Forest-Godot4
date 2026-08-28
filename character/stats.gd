extends Label

func _process(_delta: float) -> void:
	text = """
FPS: %d
Frame Time: %.2f ms
""" % [
		Engine.get_frames_per_second(),
		1000.0 / Engine.get_frames_per_second()
	]
