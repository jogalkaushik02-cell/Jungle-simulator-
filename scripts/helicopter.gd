extends CharacterBody3D

@export var max_thrust := 17.0
@export var cam_dist := 12.0
@export var enter_radius := 5.0
@export var model_length := 7.0

const GRAVITY := 9.8
const SPOOL_IN := 0.4
const SPOOL_OUT := 0.25
const COLLECTIVE_RATE := 0.55
const PITCH_MAX := 0.42
const ROLL_MAX := 0.35
const HOVER := 0.55

@onready var model: Node3D = $Model
@onready var shape: CollisionShape3D = $Shape

var rig: CameraRig
var driver: Node = null
var _spool := 0.0
var _coll := 0.0
var _rotor_speed := 0.0
var _rotors: Array[Node3D] = []
var _rotor_axis: Array[Vector3] = []
var _audio: AudioStreamPlayer3D

func _ready() -> void:
	add_to_group("enterable")
	add_to_group("heli")
	rig = get_tree().get_first_node_in_group("camrig") as CameraRig
	ModelFit.fit(model, model_length, true)
	_gather_rotors(model)
	_audio = AudioStreamPlayer3D.new()
	_audio.max_distance = 120.0
	_audio.unit_size = 14.0
	add_child(_audio)

func _gather_rotors(n: Node) -> void:
	var low := n.name.to_lower()
	var is_rotor := n is Node3D and low.contains("rotor")
	is_rotor = is_rotor or (n is Node3D and low.contains("head"))
	if is_rotor:
		_rotors.append(n as Node3D)
		_rotor_axis.append(ModelFit.spin_axis(n as Node3D))
	for c in n.get_children():
		_gather_rotors(c)

func activate(who: Node) -> void:
	driver = who
	if driver != null and driver.has_method("set_riding"):
		driver.call("set_riding", true)
	GameInput.occupied = self
	if rig != null:
		rig.set_target(self, cam_dist, true, 1.8)
	Sound.engine_loop(_audio)

func _physics_process(delta: float) -> void:
	if driver == null:
		return
	var free := _coll > 0.4
	free = free or global_position.y > Terrain.height_at(global_position.x, global_position.z) + 3.0

	if free:
		_spool = minf(1.0, _spool + SPOOL_IN * delta)
		var lifted := GameInput.lift > 0.0 or _coll > 0.45
		if lifted:
			_coll = minf(1.0, _coll + COLLECTIVE_RATE * delta)
		else:
			_coll = maxf(HOVER, _coll - COLLECTIVE_RATE * delta)
	else:
		_spool = maxf(0.0, _spool - SPOOL_OUT * delta)
		_coll = maxf(0.0, _coll - COLLECTIVE_RATE * 1.5 * delta)

	var thrust := Vector3.UP * (_coll * _spool * max_thrust)
	var vel := velocity + (thrust - Vector3.UP * GRAVITY) * delta
	vel -= vel * (0.35 * delta)
	vel -= vel * vel.length() * (0.012 * delta)
	velocity = vel

	var j := GameInput.joy
	rotation.y -= GameInput.consume_look_x() * 0.004
	var pitch_rate := -j.y * PITCH_MAX
	var roll_rate := j.x * ROLL_MAX
	var rb := global_transform.basis
	rotate(rb.x, pitch_rate * delta * 2.0)
	var fwd := -rb.z
	var bank := fwd * (roll_rate * delta * 1.2)
	velocity.x += bank.x
	velocity.z += bank.z

	move_and_slide()

	var floor_y := Terrain.height_at(global_position.x, global_position.z) + 0.1
	if global_position.y < floor_y:
		global_position.y = floor_y
		if velocity.y < 0.0:
			velocity.y = 0.0
		var slide := Vector2(velocity.x, velocity.z) * (1.0 - 0.5 * delta)
		velocity.x = slide.x
		velocity.z = slide.y

	_rotor_speed = 6.0 + _spool * 50.0
	for i in _rotors.size():
		_rotors[i].rotate(_rotor_axis[i], _rotor_speed * delta)

	if _audio != null:
		_audio.volume_db = clampf(-38.0 + _spool * 34.0, -50.0, -4.0)
		_audio.pitch_scale = 0.8 + _spool * 0.35 + _coll * 0.1

	GameInput.hint = self
	GameInput.near_hint = true
	if GameInput.interact_edge and absf(velocity.y) < 4.0:
		_exit()

func _exit() -> void:
	if global_position.y > Terrain.height_at(global_position.x, global_position.z) + 2.0:
		return
	var spot := global_position + global_transform.basis.x * 3.2
	spot.y = Terrain.height_at(spot.x, spot.z) + 0.1
	if driver != null and driver.has_method("exit_to"):
		driver.call("exit_to", spot)
	driver = null
	GameInput.occupied = null
	GameInput.hint = null
	GameInput.near_hint = false
	if rig != null and rig.target == self:
		rig.set_target(null, cam_dist, false)
	if _audio != null:
		_audio.stop()
