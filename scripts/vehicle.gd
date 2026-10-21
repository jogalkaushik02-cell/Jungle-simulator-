class_name Vehicle
extends CharacterBody3D

@export var max_speed := 15.0
@export var reverse_speed := 5.0
@export var accel := 7.0
@export var steer_rate := 1.5
@export var model_length := 4.3
@export var cam_dist := 9.0
@export var enter_radius := 4.5

const GRAVITY := 22.0

@onready var model: Node3D = $Model
@onready var shape: CollisionShape3D = $Shape

var rig: CameraRig
var driver: Node = null
var _speed := 0.0
var _wheels: Array[Node3D] = []
var _spin_axis: Array[Vector3] = []
var _engine: AudioStreamPlayer3D
var _started := false

func _ready() -> void:
	add_to_group("enterable")
	rig = get_tree().get_first_node_in_group("camrig") as CameraRig
	ModelFit.fit(model, model_length, true)
	_gather_wheels(model)
	_engine = AudioStreamPlayer3D.new()
	_engine.max_distance = 55.0
	_engine.unit_size = 10.0
	add_child(_engine)

func _gather_wheels(n: Node) -> void:
	if n is Node3D and n.name.to_lower().contains("wheel"):
		_wheels.append(n as Node3D)
		_spin_axis.append(ModelFit.spin_axis(n as Node3D))
	for c in n.get_children():
		_gather_wheels(c)

func activate(who: Node) -> void:
	driver = who
	if driver != null and driver.has_method("set_riding"):
		driver.call("set_riding", true)
	GameInput.occupied = self
	if rig != null:
		rig.set_target(self, cam_dist, true, 1.4)
	if not _started:
		_started = true
		Sound.engine_start(_engine)

func _physics_process(delta: float) -> void:
	if driver == null:
		return
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	var j := GameInput.joy
	var throttle := clampf(-j.y, -1.0, 1.0)
	var steer := clampf(j.x, -1.0, 1.0)

	var target := throttle * (max_speed if throttle >= 0.0 else reverse_speed)
	if throttle != 0.0:
		_speed = move_toward(_speed, target, accel * delta)
	else:
		_speed = move_toward(_speed, 0.0, accel * 0.8 * delta)

	var turn := steer * steer_rate * delta * clampf(absf(_speed) / 4.0, 0.0, 1.6)
	if _speed < 0.0:
		turn = -turn
	rotation.y += turn

	var fwd := -global_transform.basis.z
	velocity.x = fwd.x * _speed
	velocity.z = fwd.z * _speed
	move_and_slide()

	for i in _wheels.size():
		_wheels[i].rotate(_spin_axis[i], _speed * delta * 2.0)

	if _engine != null:
		_engine.volume_db = clampf(-32.0 + absf(_speed) * 1.4, -50.0, -10.0)
		_engine.pitch_scale = 0.85 + absf(_speed) / max_speed * 0.6

	GameInput.hint = self
	GameInput.near_hint = true
	if GameInput.interact_edge:
		_exit()

func _exit() -> void:
	var spot := global_position + global_transform.basis.x * 2.6
	spot.y = Terrain.height_at(spot.x, spot.z) + 0.1
	if driver != null and driver.has_method("exit_to"):
		driver.call("exit_to", spot)
	driver = null
	GameInput.occupied = null
	GameInput.hint = null
	GameInput.near_hint = false
	if rig != null and rig.target == self:
		rig.set_target(null, cam_dist, false)
	_speed = 0.0
	if _engine != null:
		_engine.stop()
