@tool
class_name Ledge
extends Marker3D
## A grabbable ledge. Place it exactly on the top corner of solid ground.
## facing_out points away from the ground: -1 for a left edge, 1 for a right edge.
## One fighter can hold a ledge at a time.

@export_enum("Left edge:-1", "Right edge:1") var facing_out := 1

var occupied_by: Node = null


func _ready() -> void:
	add_to_group("ledges")
	gizmo_extents = 0.3
