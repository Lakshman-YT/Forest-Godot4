extends Path3D

@export var paths : Array[Resource]
@onready var butterfly = preload("res://env models/movable/butterfly_scene/butterfly.tscn")

func _ready() -> void:
	_add_butterfly()
	var btr = butterfly.instantiate()
	$PathFollow3D.add_child(btr)
	btr.spawn_butterfly()
	
func _add_butterfly() -> void:
	$PathFollow3D.progress_ratio = 0.0
	var _tween = create_tween()
	_tween.tween_property($PathFollow3D, "progress_ratio", 1, 20)
	self.curve = paths.pick_random()
	self.rotation_degrees.y = randf_range(0,180)
	_tween.finished.connect(func ():
		_add_butterfly()
		)
