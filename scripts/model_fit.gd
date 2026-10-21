class_name ModelFit
extends RefCounted

static func _gather_aabb(node: Node3D) -> AABB:
	var result := AABB()
	var first := true
	var stack: Array[Node] = [node]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
			var mi := n as MeshInstance3D
			var b := mi.get_aabb()
			var gt := mi.global_transform
			for i in 8:
				var wp := gt * b.get_endpoint(i)
				if first:
					result = AABB(wp, Vector3.ZERO)
					first = false
				else:
					result = result.expand(wp)
		for c in n.get_children():
			stack.push_back(c)
	return result

static func fit(node: Node3D, target_longest: float, ground: bool = true) -> void:
	if node == null:
		return
	var b := _gather_aabb(node)
	if b.size.x <= 0.0001 and b.size.y <= 0.0001 and b.size.z <= 0.0001:
		return
	var longest := maxf(b.size.x, maxf(b.size.y, b.size.z))
	if longest <= 0.0001:
		return
	var s := target_longest / longest
	node.scale = node.scale * s
	if ground:
		var b2 := _gather_aabb(node)
		node.position.y -= b2.position.y

static func local_aabb(node: Node3D) -> AABB:
	var inv := node.global_transform.affine_inverse()
	var result := AABB()
	var first := true
	var stack: Array[Node] = [node]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
			var mi := n as MeshInstance3D
			var b := mi.get_aabb()
			var gt := inv * mi.global_transform
			for i in 8:
				var p := gt * b.get_endpoint(i)
				if first:
					result = AABB(p, Vector3.ZERO)
					first = false
				else:
					result = result.expand(p)
		for c in n.get_children():
			stack.push_back(c)
	if first:
		return AABB(Vector3.ZERO, Vector3.ONE)
	return result

static func spin_axis(node: Node3D) -> Vector3:
	var b := local_aabb(node)
	if b.size.x <= b.size.y and b.size.x <= b.size.z:
		return Vector3.RIGHT
	if b.size.y <= b.size.z:
		return Vector3.UP
	return Vector3.BACK

static func fit_height(node: Node3D, target_h: float, ground: bool = true) -> void:
	if node == null:
		return
	var b := _gather_aabb(node)
	if b.size.y <= 0.0001:
		return
	var s := target_h / b.size.y
	node.scale = node.scale * s
	if ground:
		var b2 := _gather_aabb(node)
		node.position.y -= b2.position.y
