extends Node3D

@export_category("Movement")
@export var move_speed: float = 5.0
@export var fast_speed: float = 20.0
@export var speed_step: float = 2.0

@export_category("Mouse")
@export var mouse_sensitivity: float = 0.002

@export var min_pitch: float = -89.0
@export var max_pitch: float = 89.0


var _pitch: float = 0.0
var _yaw: float = 0.0
var _speed: float


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_speed = move_speed


func _unhandled_input(event: InputEvent) -> void:

	# Mouse look
	if event is InputEventMouseMotion:
		_yaw -= event.relative.x * mouse_sensitivity
		_pitch -= event.relative.y * mouse_sensitivity

		_pitch = clampf(
			_pitch,
			deg_to_rad(min_pitch),
			deg_to_rad(max_pitch)
		)

		rotation = Vector3(_pitch, _yaw, 0.0)


	# Mouse wheel changes movement speed
	if event is InputEventMouseButton and event.pressed:

		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_speed += speed_step

		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_speed = maxf(
				0.1,
				_speed - speed_step
			)


func _physics_process(delta: float) -> void:

	var input := Vector3.ZERO

	# Forward / backward
	if Input.is_key_pressed(KEY_W):
		input.z -= 1.0

	if Input.is_key_pressed(KEY_S):
		input.z += 1.0

	# Left / right
	if Input.is_key_pressed(KEY_A):
		input.x -= 1.0

	if Input.is_key_pressed(KEY_D):
		input.x += 1.0

	# Up / down
	if Input.is_key_pressed(KEY_E):
		input.y += 1.0

	if Input.is_key_pressed(KEY_Q):
		input.y -= 1.0

	if input.length_squared() > 0.0:
		input = input.normalized()

		var speed := _speed

		# Shift = temporary fast movement
		if Input.is_key_pressed(KEY_SHIFT):
			speed = fast_speed

		global_position += global_basis * input * speed * delta
