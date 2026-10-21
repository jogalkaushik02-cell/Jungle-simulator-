extends Node

const DIR := "res://assets/sounds/"

var _cache: Dictionary = {}
var _pool: Array[AudioStreamPlayer] = []
var _pool_idx := 0
var _amb: Dictionary = {}
var _target: Node3D = null

func _ready() -> void:
	for i in 8:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_pool.append(p)
	_amb["wind"] = _make_amb("wind.wav", -22.0)
	_amb["forest"] = _make_amb("forest.wav", -26.0)
	_amb["river"] = _make_amb("river.wav", -24.0)
	_amb["birds"] = _make_amb("birds.wav", -30.0)

func _make_amb(file: String, vol: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = get_stream(file, true)
	p.volume_db = vol
	p.bus = "Master"
	add_child(p)
	if p.stream != null:
		p.play()
	return p

func get_stream(file: String, looped: bool) -> AudioStream:
	var key := file + ("_loop" if looped else "")
	if _cache.has(key):
		return _cache[key]
	var path := DIR + file
	if not ResourceLoader.exists(path):
		_cache[key] = null
		return null
	var st := load(path) as AudioStream
	if st != null and looped and st is AudioStreamWAV:
		var w := st as AudioStreamWAV
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = w.data.size() / 2
		if w.stereo:
			w.loop_end = w.data.size() / 4
	_cache[key] = st
	return st

func _play(file: String, vol: float, pitch: float) -> void:
	var st := get_stream(file, false)
	if st == null:
		return
	var p := _pool[_pool_idx]
	_pool_idx = (_pool_idx + 1) % _pool.size()
	p.stream = st
	p.volume_db = vol
	p.pitch_scale = pitch
	p.play()

func footstep() -> void:
	_play("step.wav", -16.0, randf_range(0.9, 1.15))

func ui_click() -> void:
	_play("ui.wav", -12.0, 1.0)

func engine_start(host: AudioStreamPlayer3D) -> void:
	var st := get_stream("engine_start.wav", false)
	if st != null and host != null:
		host.stream = st
		host.play()
		await get_tree().create_timer(st.get_length()).timeout
	engine_loop(host)

func engine_loop(host: AudioStreamPlayer3D) -> void:
	if host == null:
		return
	var st := get_stream("engine.wav", true)
	if st == null:
		return
	host.stream = st
	host.play()

func _process(_delta: float) -> void:
	var rig := get_tree().get_first_node_in_group("camrig")
	if rig is CameraRig and rig.target != null and is_instance_valid(rig.target):
		_target = rig.target
	if _target == null:
		return
	var pos := _target.global_position
	var h := pos.y
	var d_river := absf(pos.x - Terrain.river_center(pos.z))
	var f_forest := clampf(1.0 - absf(h - 6.0) / 22.0, 0.0, 1.0)
	var f_river := clampf(1.0 - d_river / 26.0, 0.0, 1.0)
	var f_wind := clampf(h / 40.0, 0.15, 1.0)
	_set_vol("wind", lerpf(-30.0, -16.0, f_wind))
	_set_vol("forest", lerpf(-40.0, -22.0, f_forest))
	_set_vol("river", lerpf(-44.0, -20.0, f_river))
	_set_vol("birds", lerpf(-42.0, -26.0, f_forest * (1.0 - f_river * 0.5)))

func _set_vol(name: String, db: float) -> void:
	if _amb.has(name):
		(_amb[name] as AudioStreamPlayer).volume_db = db
