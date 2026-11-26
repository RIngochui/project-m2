extends Node3D
## Gray-box room for tuning fighter movement.
## Handles blast-zone KOs, the follow camera, frame advance and the debug overlay.

## Leave these bounds and you're KO'd. In real rooms, the camera bounds will
## double as blast lines.
@export var blast_min := Vector2(-28, -14)
@export var blast_max := Vector2(28, 18)
@export var fighter_path: NodePath = ^"Fighter"
@export var spawn_path: NodePath = ^"Spawn"

var kos := 0
var _paused := false

@onready var fighter: Fighter = get_node(fighter_path)
@onready var spawn: Marker3D = get_node(spawn_path)
@onready var camera: Camera3D = $Camera
@onready var overlay: Label = $Debug/Overlay


func _ready() -> void:
	fighter.global_position = spawn.global_position
	camera.global_position = fighter.global_position + Vector3(0, 2.0, 16)


func _physics_process(_delta: float) -> void:
	var p := fighter.global_position
	if p.x < blast_min.x or p.x > blast_max.x or p.y < blast_min.y or p.y > blast_max.y:
		kos += 1
		fighter.respawn(spawn.global_position)


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("debug_pause"):
		_paused = not _paused
		get_tree().paused = _paused
	if Input.is_action_just_pressed("debug_step") and _paused:
		_step_one_frame()
	if Input.is_action_just_pressed("debug_overlay"):
		overlay.visible = not overlay.visible
	if Input.is_action_just_pressed("debug_reset"):
		fighter.respawn(spawn.global_position)

	var target := fighter.global_position + Vector3(0, 2.0, 16)
	camera.global_position = camera.global_position.lerp(target, 1.0 - exp(-6.0 * delta))
	if overlay.visible:
		overlay.text = _overlay_text()


func _step_one_frame() -> void:
	get_tree().paused = false
	await get_tree().physics_frame  # frame N starts; the fighter runs in it
	await get_tree().physics_frame  # frame N+1 starts; pause before it runs
	get_tree().paused = true


func _overlay_text() -> String:
	var f := fighter
	var s := f.input.stick() if f.input else Vector2.ZERO
	var lines := PackedStringArray()
	lines.append("%s  frame %d%s" % [String(f.state).to_upper(), f.state_frame, "   [PAUSED]" if _paused else ""])
	lines.append("vel  x %+.2f  y %+.2f  (units/frame)" % [f.vel.x, f.vel.y])
	lines.append("ground %s%s   jumps %d   airdodge %s" % [
		"yes" if f.is_grounded() else "no",
		" (platform)" if f.on_platform else "",
		f.jumps_left,
		"ready" if f.airdodge_available else "used"])
	lines.append("fastfall %s   intangible %d   facing %s" % [
		"yes" if f.fastfalling else "no", f.intangible_frames, "R" if f.facing > 0 else "L"])
	lines.append("stick (%+.2f, %+.2f)   KOs %d" % [s.x, s.y, kos])
	var hist := PackedStringArray()
	for h in f.history:
		hist.append("%s %d" % [h[0], h[1]])
	lines.append("prev: " + "  <  ".join(hist))
	lines.append("")
	lines.append("Move WASD/arrows  Jump Space  Airdodge Shift  Walk hold Ctrl")
	lines.append("P pause   . step frame   R reset   F1 hide")
	return "\n".join(lines)
