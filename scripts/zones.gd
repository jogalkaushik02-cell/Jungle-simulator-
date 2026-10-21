extends Control

var _zone := ""
var _zone_t := 0.0

func _ready() -> void:
	process_priority = 10

func _zone_for(x: float, y: float) -> String:
	if y > 90.0:
		return "Snowy Mountains"
	if y < 2.0 and absf(x - Terrain.river_center(y)) < 22.0:
		return "Riverside"
	if y < -95.0:
		return "Airstrip"
	if y > 0.0:
		return "Jungle"
	return "Meadow"

func _process(delta: float) -> void:
	_zone_t -= delta
	if _zone_t > 0.0:
		return
	_zone_t = 0.4
	var rig := get_tree().get_first_node_in_group("camrig")
	if not rig is CameraRig or rig.target == null:
		return
	var t := rig.target
	var z := _zone_for(t.global_position.x, t.global_position.z)
	if z != _zone:
		_zone = z
		var lbl := get_node_or_null("ZoneLabel") as Label
		if lbl != null:
			lbl.text = z
