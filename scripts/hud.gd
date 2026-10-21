extends Control

const JOY_BASE := 78.0
const JOY_KNOB := 34.0
const JOY_LIMIT := 70.0
const LOOK_SENS := 0.0042

var _joy_id := -1
var _joy_center := Vector2.ZERO
var _knob: Control
var _base: Control
var _zones: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_base = _circle(JOY_BASE, Color(1, 1, 1, 0.15))
	_knob = _circle(JOY_KNOB, Color(1, 1, 1, 0.35))
	_btn("CAM", Vector2(-210, 40), Vector2(150, 90))
	_btn("USE", Vector2(-300, -300), Vector2(120, 120))
	_btn("JUMP", Vector2(-450, -190), Vector2(120, 120))
	_btn("UP", Vector2(-470, -470), Vector2(120, 120))
	_btn("DN", Vector2(-300, -470), Vector2(120, 120))
	call_deferred("_layout")

func _circle(radius: float, col: Color) -> Control:
	var c := Control.new()
	var style := StyleBoxFlat.new()
	style.bg_color = col
	var r := int(radius)
	style.corner_radius_top_left = r
	style.corner_radius_top_right = r
	style.corner_radius_bottom_left = r
	style.corner_radius_bottom_right = r
	c.add_theme_stylebox_override("panel", style)
	c.size = Vector2(radius * 2.0, radius * 2.0)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(c)
	return c

func _btn(label: String, off: Vector2, size: Vector2) -> void:
	var b := Button.new()
	b.text = label
	b.custom_minimum_size = size
	b.size = size
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.focus_mode = Control.FOCUS_NONE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.18)
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	b.add_theme_stylebox_override("normal", style)
	b.add_theme_stylebox_override("hover", style)
	b.add_theme_stylebox_override("pressed", style)
	add_child(b)
	_zones[label] = {"node": b, "off": off, "size": size}

func _layout() -> void:
	var vp := size
	if vp.x <= 1.0:
		vp = get_viewport_rect().size
	for key in _zones:
		var z: Dictionary = _zones[key]
		var off: Vector2 = z["off"]
		var sz: Vector2 = z["size"]
		var pos := Vector2(vp.x + off.x - sz.x, vp.y + off.y - sz.y)
		(z["node"] as Button).position = pos
	_joy_center = Vector2(190.0, vp.y - 190.0)
	_base.position = _joy_center - Vector2(JOY_BASE, JOY_BASE)
	_knob.position = _joy_center - Vector2(JOY_KNOB, JOY_KNOB)

func _rect(key: String) -> Rect2:
	var z: Dictionary = _zones[key]
	var b := z["node"] as Button
	return Rect2(b.position, b.size)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			_press(t.index, t.position)
		else:
			_release(t.index)
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if d.index == _joy_id:
			_drag_joy(d.position)
		else:
			GameInput.look += d.relative * LOOK_SENS
	elif event is InputEventMouseButton:
		var m := event as InputEventMouseButton
		if m.pressed:
			_press(0, m.position)
		else:
			_release(0)
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if _joy_id < 0:
			GameInput.look += mm.relative * LOOK_SENS

func _press(id: int, pos: Vector2) -> void:
	if _rect("CAM").has_point(pos):
		_flash("CAM"); GameInput.cam_toggle_edge = true; Sound.ui_click(); return
	if _rect("USE").has_point(pos):
		_flash("USE"); GameInput.interact_edge = true; Sound.ui_click(); return
	if _rect("JUMP").has_point(pos):
		_flash("JUMP"); GameInput.jump_edge = true; Sound.ui_click(); return
	if _rect("UP").has_point(pos):
		_flash("UP"); GameInput.lift_touch = 1.0; return
	if _rect("DN").has_point(pos):
		_flash("DN"); GameInput.lift_touch = -1.0; return
	var vp := size
	if pos.x < vp.x * 0.45 and pos.y > vp.y * 0.40:
		_joy_id = id
		_drag_joy(pos)

func _release(id: int) -> void:
	if id == _joy_id:
		_joy_id = -1
		GameInput.joy_move = Vector2.ZERO
		_knob.position = _joy_center - Vector2(JOY_KNOB, JOY_KNOB)
	GameInput.lift_touch = 0.0

func _drag_joy(pos: Vector2) -> void:
	var off := pos - _joy_center
	if off.length() > JOY_LIMIT:
		off = off.normalized() * JOY_LIMIT
	_knob.position = _joy_center + off - Vector2(JOY_KNOB, JOY_KNOB)
	GameInput.joy_move = off / JOY_LIMIT

func _flash(key: String) -> void:
	var b := (_zones[key]["node"] as Button)
	b.modulate = Color(1, 1, 1, 1)
	var tw := create_tween()
	tw.tween_property(b, "modulate", Color(1, 1, 1, 0.85), 0.25)

func _process(_delta: float) -> void:
	var occ := GameInput.occupied
	var heli := occ != null and occ.is_in_group("heli")
	_vis("CAM", true)
	_vis("USE", true)
	_vis("JUMP", occ == null)
	_vis("UP", heli)
	_vis("DN", heli)

func _vis(key: String, v: bool) -> void:
	(_zones[key]["node"] as Button).visible = v
