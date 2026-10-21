extends Node

var joy_move := Vector2.ZERO
var key_joy := Vector2.ZERO
var look := Vector2.ZERO
var jump_edge := false
var interact_edge := false
var cam_toggle_edge := false
var near_hint := false
var hint: Node3D = null
var occupied: Node3D = null
var lift_touch := 0.0
var lift_key := 0.0

var joy: Vector2:
	get:
		return (joy_move + key_joy).limit_length(1.0)

var lift: float:
	get:
		return clampf(lift_touch + lift_key, -1.0, 1.0)

func _ready() -> void:
	process_physics_priority = 100

func consume_look_x() -> float:
	var x := look.x
	look.x = 0.0
	return x

func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or key.echo:
		return
	_update_keys(key.pressed, key.physical_keycode)

func _update_keys(pressed: bool, k: Key) -> void:
	match k:
		KEY_A, KEY_LEFT:
			key_joy.x = -1.0 if pressed else 0.0
		KEY_D, KEY_RIGHT:
			key_joy.x = 1.0 if pressed else 0.0
		KEY_W, KEY_UP:
			key_joy.y = -1.0 if pressed else 0.0
		KEY_S, KEY_DOWN:
			key_joy.y = 1.0 if pressed else 0.0
		KEY_R:
			lift_key = 1.0 if pressed else 0.0
		KEY_F:
			lift_key = -1.0 if pressed else 0.0
		KEY_SPACE:
			if pressed:
				jump_edge = true
		KEY_E:
			if pressed:
				interact_edge = true
		KEY_C:
			if pressed:
				cam_toggle_edge = true

func _physics_process(_delta: float) -> void:
	jump_edge = false
	interact_edge = false
	cam_toggle_edge = false
	look = Vector2.ZERO
