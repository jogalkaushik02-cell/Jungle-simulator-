extends CharacterBody3D

@export var speed := 5.0
@export var jump_velocity := 4.8
@export var model_yaw_offset := 0.0
@export var enter_radius := 4.5

const GRAVITY := 22.0

@onready var model: Node3D = $Model
@onready var shape: CollisionShape3D = $Shape

var rig: CameraRig
var _anim: AnimationPlayer
var _anim_name := ""
var _step := 0.0
var _riding := false

func _ready() -> void:
	rig = get_tree().get_first_node_in_group("camrig") as CameraRig
	_anim = _find_anim(self)
	if _anim != null and not _anim.has_animation("walk"):
		_anim = null
	if rig != null:
		rig.set_target(self, rig.third_distance, false, 1.6)

func _find_anim(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for c in n.get_children():
		var r := _find_anim(c)
		if r != null:
			return r
	return null

func _physics_process(delta: float) -> void:
	if _riding:
		return
	if GameInput.interact_edge and GameInput.hint != null and GameInput.hint.has_method("activate"):
		GameInput.hint.call("activate", self)
		return

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	elif GameInput.jump_edge:
		velocity.y = jump_velocity

	var j := GameInput.joy
	var dir := Vector3.ZERO
	if rig != null and j.length_squared() > 0.0001:
		var f := Vector3(-sin(rig.yaw), 0.0, -cos(rig.yaw))
		var right := Vector3(-f.z, 0.0, f.x)
		dir = f * -j.y + right * j.x
		if dir.length_squared() > 1.0:
			dir = dir.normalized()
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	move_and_slide()

	var hspeed := Vector2(velocity.x, velocity.z).length()
	if hspeed > 0.2:
		var want := atan2(-velocity.x, -velocity.z) + model_yaw_offset
		model.rotation.y = lerp_angle(model.rotation.y, want, 1.0 - exp(-14.0 * delta))

	if _anim != null:
		if hspeed > 0.3:
			if _anim_name != "walk":
				_anim.play("walk")
				_anim_name = "walk"
			_anim.speed_scale = clampf(hspeed / 5.0, 0.4, 1.6)
		else:
			_anim.speed_scale = 0.0

	if is_on_floor() and hspeed > 0.5:
		_step -= hspeed * delta
		if _step <= 0.0:
			_step = 0.75
			Sound.footstep()

	_update_hints()

func _update_hints() -> void:
	var best: Node3D = null
	var best_d := enter_radius
	for n in get_tree().get_nodes_in_group("enterable"):
		var v := n as Node3D
		if v == null or not is_instance_valid(v):
			continue
		var d := global_position.distance_to(v.global_position)
		if d < best_d:
			best_d = d
			best = v
	GameInput.hint = best
	GameInput.near_hint = best != null

func set_riding(on: bool) -> void:
	_riding = on
	visible = not on
	shape.set_deferred("disabled", on)
	velocity = Vector3.ZERO
	if on:
		GameInput.hint = null
		GameInput.near_hint = false

func exit_to(pos: Vector3) -> void:
	global_position = pos
	set_riding(false)
	if rig != null:
		rig.set_target(self, rig.third_distance, false, 1.6)
