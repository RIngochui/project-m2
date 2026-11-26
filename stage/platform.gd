@tool
class_name Platform
extends Node3D
## A pass-through platform. Fighters jump up through it, land on top, and drop
## through by flicking down. The node's position is the center of the top edge.
##
## Platforms are not physics colliders: the fighter checks them itself, so
## one-way behavior is exact and works the same for players and enemies.

@export var width := 3.2:
	set(v):
		width = v
		_build_visual()

var _mesh: MeshInstance3D


func _ready() -> void:
	add_to_group("platforms")
	_build_visual()


func top() -> float:
	return global_position.y


func left() -> float:
	return global_position.x - width * 0.5


func right() -> float:
	return global_position.x + width * 0.5


func _build_visual() -> void:
	if not is_inside_tree():
		return
	if _mesh == null:
		_mesh = MeshInstance3D.new()
		_mesh.name = "Visual"
		add_child(_mesh, false, Node.INTERNAL_MODE_FRONT)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.55, 0.6, 0.7)
		_mesh.material_override = mat
	var box := BoxMesh.new()
	box.size = Vector3(width, 0.18, 1.6)
	_mesh.mesh = box
	_mesh.position = Vector3(0, -0.09, 0)
