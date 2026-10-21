class_name Terrain
extends StaticBody3D

const SIZE := 400.0
const CELLS := 200
const MAP_W := 401
const WATER_Y := -0.98

static var _inst: Terrain = null

var _base := FastNoiseLite.new()
var _detail := FastNoiseLite.new()
var _ridge := FastNoiseLite.new()

func _ready() -> void:
	_inst = self
	_setup_noise()
	_build_mesh()
	_build_collision()

static func height_at(x: float, z: float) -> float:
	if _inst == null:
		return 0.0
	return _inst._h(x, z)

static func river_center(z: float) -> float:
	return 52.0 + sin(z * 0.013) * 26.0 + sin(z * 0.041 + 1.7) * 9.0

static func normal_at(x: float, z: float) -> Vector3:
	if _inst == null:
		return Vector3.UP
	return _inst._n(x, z)

func _setup_noise() -> void:
	_base.seed = 1337
	_base.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_base.fractal_type = FastNoiseLite.FRACTAL_FBM
	_base.frequency = 0.011
	_base.fractal_octaves = 4

	_detail.seed = 991
	_detail.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_detail.fractal_type = FastNoiseLite.FRACTAL_FBM
	_detail.frequency = 0.06
	_detail.fractal_octaves = 2

	_ridge.seed = 4242
	_ridge.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_ridge.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	_ridge.frequency = 0.008
	_ridge.fractal_octaves = 4

func _h(x: float, z: float) -> float:
	var h := 2.5 + _base.get_noise_2d(x, z) * 4.5 + _detail.get_noise_2d(x, z) * 0.8
	var mz := smoothstep(60.0, 200.0, z)
	if mz > 0.001:
		var r := maxf(_ridge.get_noise_2d(x, z), 0.0)
		h += mz * (34.0 + r * 26.0)
	var px := 1.0 - smoothstep(5.0, 25.0, x)
	var pz := 1.0 - smoothstep(-95.0, -75.0, z)
	h = lerpf(h, 0.0, minf(px, pz))
	var rc := 52.0 + sin(z * 0.013) * 26.0 + sin(z * 0.041 + 1.7) * 9.0
	var d := absf(x - rc)
	if d < 14.0:
		var w := 1.0 - smoothstep(4.0, 14.0, d)
		h = lerpf(h, -2.2 if z > 60.0 else -1.6, w)
	return h

func _n(x: float, z: float) -> Vector3:
	var hl := _h(x - 1.0, z)
	var hr := _h(x + 1.0, z)
	var hd := _h(x, z - 1.0)
	var hu := _h(x, z + 1.0)
	return Vector3(hl - hr, 2.0, hd - hu).normalized()

func _build_mesh() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var step := SIZE / float(CELLS)
	var half := SIZE * 0.5
	for iz in CELLS + 1:
		for ix in CELLS + 1:
			var x := -half + float(ix) * step
			var z := -half + float(iz) * step
			st.set_normal(_n(x, z))
			st.set_uv(Vector2(x, z) * 0.14)
			st.add_vertex(Vector3(x, _h(x, z), z))
	st.index()
	st.generate_tangents()
	var mesh := st.commit()

	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/terrain.gdshader")
	var g := "res://assets/textures/ground/"
	mat.set_shader_parameter("forest_albedo", load(g + "forest_floor_diff_1k.jpg"))
	mat.set_shader_parameter("forest_normal", load(g + "forest_floor_nor_gl_1k.jpg"))
	mat.set_shader_parameter("mud_albedo", load(g + "brown_mud_leaves_01_diff_1k.jpg"))
	mat.set_shader_parameter("mud_normal", load(g + "brown_mud_leaves_01_nor_gl_1k.jpg"))
	mat.set_shader_parameter("rock_albedo", load(g + "rock_diff_1k.jpg"))
	mat.set_shader_parameter("rock_normal", load(g + "rock_nor_gl_1k.jpg"))
	mat.set_shader_parameter("snow_albedo", load(g + "snow_02_diff_1k.jpg"))
	mat.set_shader_parameter("snow_normal", load(g + "snow_02_nor_gl_1k.jpg"))
	mesh.surface_set_material(0, mat)

	var mi := MeshInstance3D.new()
	mi.name = "Ground"
	mi.mesh = mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(mi)

func _build_collision() -> void:
	var map := PackedFloat32Array()
	map.resize(MAP_W * MAP_W)
	var half := SIZE * 0.5
	for iz in MAP_W:
		var row := iz * MAP_W
		var z := -half + float(iz)
		for ix in MAP_W:
			map[row + ix] = _h(-half + float(ix), z)
	var shape := HeightMapShape3D.new()
	shape.map_width = MAP_W
	shape.map_depth = MAP_W
	shape.map_data = map
	var cs := CollisionShape3D.new()
	cs.name = "GroundShape"
	cs.shape = shape
	add_child(cs)
