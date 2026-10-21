extends MultiMeshInstance3D

const AREA := 380.0
const HALF := AREA * 0.5
const MAX_PER_KIND := 1500

class Kind:
	var mesh: Mesh
	var target_h: float
	var list: Array = []

var _kinds: Array[Kind] = []
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.seed = 20321
	_register("res://assets/nature/pine-tree.glb", 16.0)
	_register("res://assets/nature/birch-tree.glb", 11.0)
	_register("res://assets/nature/oak-tree.glb", 13.0)
	_register("res://assets/nature/dead-tree.glb", 9.0)
	_register("res://assets/nature/bush.glb", 1.6)
	_register("res://assets/nature/fern.glb", 0.9)
	_register("res://assets/nature/grass-clump.glb", 0.7)
	_register("res://assets/nature/boulder-rock-set.glb", 2.0)
	_register("res://assets/nature/snowy-pine-tree.glb", 13.0)
	_register("res://assets/nature/cattail.glb", 1.2)
	_register("res://assets/nature/reed.glb", 1.0)
	_register("res://assets/nature/forest-mushroom.glb", 0.4)
	_scatter()
	_commit()

func _register(path: String, target_h: float) -> void:
	var ps := load(path) as PackedScene
	if ps == null:
		return
	var inst := ps.instantiate()
	var mesh: Mesh = null
	var stack: Array[Node] = [inst]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
			mesh = (n as MeshInstance3D).mesh
			break
		for c in n.get_children():
			stack.push_back(c)
	inst.free()
	if mesh == null:
		return
	var k := Kind.new()
	k.mesh = mesh
	k.target_h = target_h
	_kinds.append(k)

func _scatter() -> void:
	for _i in 42000:
		var x := _rng.randf_range(-HALF, HALF)
		var z := _rng.randf_range(-HALF, HALF)
		var h := Terrain.height_at(x, z)
		var n := Terrain.normal_at(x, z)
		var slope := 1.0 - n.y
		var d_river := absf(x - Terrain.river_center(z))

		if h < -1.0:
			continue

		var pick := -1
		if h > 24.0 and slope < 0.5:
			pick = 8 if _rng.randf() < 0.7 else 7
		elif d_river < 16.0 and d_river > 3.5:
			pick = 9 if _rng.randf() < 0.5 else 10
		elif h > 1.0 and h < 14.0 and z > -60.0 and d_river > 6.0 and slope < 0.55:
			var r := _rng.randf()
			if r < 0.30:
				pick = 0
			elif r < 0.50:
				pick = 1
			elif r < 0.62:
				pick = 2
			elif r < 0.70:
				pick = 3
			elif r < 0.86:
				pick = 4
			elif r < 0.94:
				pick = 5
			else:
				pick = 11
		elif h > 0.5 and h < 4.5 and slope < 0.3:
			var r2 := _rng.randf()
			if r2 < 0.5:
				pick = 6
			elif r2 < 0.75:
				pick = 4
			elif r2 < 0.9:
				pick = 7
		elif slope > 0.5 and _rng.randf() < 0.4:
			pick = 7

		if pick < 0 or pick >= _kinds.size():
			continue
		if _kinds[pick].list.size() >= MAX_PER_KIND:
			continue
		var scale := 0.85 + _rng.randf() * 0.4
		_kinds[pick].list.append(Vector3(x, h, z))

func _commit() -> void:
	for k in _kinds:
		if k.list.is_empty():
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = k.mesh
		mm.instance_count = k.list.size()
		var s := k.target_h / maxf(_mesh_height(k.mesh), 0.01)
		for i in k.list.size():
			var p: Vector3 = k.list[i]
			var scale := s * (0.85 + _rng.randf() * 0.4)
			var basis := Basis().scaled(Vector3(scale, scale, scale))
			basis = basis.rotated(Vector3.UP, _rng.randf() * TAU)
			mm.set_instance_transform(i, Transform3D(basis, p))
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		add_child(mmi)

func _mesh_height(m: Mesh) -> float:
	return m.get_aabb().size.y
