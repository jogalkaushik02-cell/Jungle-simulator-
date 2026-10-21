class_name CameraRig
extends Node3D

@export var sens := 0.0055
@export var third_distance := 7.0
@export var first_distance := 0.45

var yaw := 0.0
var pitch := -0.28
var target: Node3D = null
var dist := 7.0
var aim_h := 1.55
var follow_yaw := false
var fp := false
var _snapped := false

@onready var cam: Camera3D = $Camera3D

func set_target(t: Node3D, d: float, follow: bool, aim: float = 1.55) -> void:
	target = t
	dist = d
	follow_yaw = follow
	aim_h = aim
	_snapped = false
	if t == null:
		return
	if follow:
		var f := -t.global_transform.basis.z
		f.y = 0.0
		if f.length_squared() > 0.0004:
			f = f.normalized()
			yaw = atan2(-f.x, -f.z)
	elif not follow:
		var m := t.find_child("Model", true, false)
		if m is Node3D:
			(m as Node3D).visible = not fp

func _process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		target = null
		return
	var lk := GameInput.look
	if not follow_yaw:
		yaw -= lk.x * sens
	pitch = clampf(pitch - lk.y * sens, -0.35, 1.15)
	if GameInput.cam_toggle_edge and GameInput.occupied == null:
		fp = not fp
		var m := target.find_child("Model", true, false)
		if m is Node3D:
			(m as Node3D).visible = not fp
	if follow_yaw:
		var f := -target.global_transform.basis.z
		f.y = 0.0
		if f.length_squared() > 0.0004:
			f = f.normalized()
			yaw = lerp_angle(yaw, atan2(-f.x, -f.z), 1.0 - exp(-4.0 * delta))

	var aim := target.global_position + Vector3(0.0, aim_h, 0.0)
	var dir := Vector3(-sin(yaw) * cos(pitch), sin(pitch), -cos(yaw) * cos(pitch))
	var wanted: Vector3

	if fp:
		if follow_yaw:
			var ff := -target.global_transform.basis.z
			ff.y = 0.0
			ff = ff.normalized() if ff.length_squared() > 0.0004 else Vector3(0.0, 0.0, -1.0)
			dir = (ff * cos(pitch) + Vector3.UP * sin(pitch)).normalized()
		wanted = aim
		_place(wanted, wanted + dir, true)
		return

	var forward := Vector3(-sin(yaw), 0.0, -cos(yaw))
	wanted = aim - forward * (dist * cos(pitch)) + Vector3.UP * (-dist * sin(pitch))
	var ground := Terrain.height_at(wanted.x, wanted.z) + 0.35
	if wanted.y < ground:
		wanted.y = ground

	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(aim, wanted)
	if target is CollisionObject3D:
		q.exclude = [(target as CollisionObject3D).get_rid()]
	var hit := space.intersect_ray(q)
	if not hit.is_empty():
		var p: Vector3 = hit["position"]
		var pull := aim - p
		if pull.length_squared() > 0.0001:
			wanted = p + pull.normalized() * 0.35
	_place(wanted, aim, false)

func _place(pos: Vector3, look_at: Vector3, snap: bool) -> void:
	if snap or not _snapped:
		cam.global_position = pos
		_snapped = true
	else:
		cam.global_position = cam.global_position.lerp(pos, 1.0 - exp(-14.0 * get_process_delta_time()))
	if (look_at - cam.global_position).length_squared() > 0.0001:
		cam.look_at(look_at)
