extends SceneTree
## Automated movement tests. Each case puts the fighter somewhere in the test
## room, feeds it a fixed input script, and checks what happened frame by frame.
##
## Run from the project folder:
##   godot --headless --fixed-fps 60 --script res://tests/movement_tests.gd
## Exit code is the number of failed cases.

var room: Node3D
var fighter: Fighter
var input: ScriptedInput
var samples: Array = []
var transitions: Array = []
var failures := 0
var results: Array[String] = []


func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/test_room.tscn")
	room = scene.instantiate()
	fighter = room.get_node("Fighter")
	fighter.use_player_input = false
	input = ScriptedInput.new()
	fighter.input = input
	fighter.state_changed.connect(func(from, to): transitions.append([from, to, fighter.history[0][1]]))
	root.add_child(room)
	_run_all.call_deferred()


func _run_all() -> void:
	await _case_short_vs_full_hop()
	await _case_double_jump()
	await _case_run()
	await _case_dash_dance()
	await _case_wavedash()
	await _case_fast_fall()
	await _case_platform_land_and_drop()
	await _case_ledge_grab_and_getup()
	await _case_ledge_roll()
	await _case_ledge_dash()
	await _case_ledge_cancel()
	await _case_run_off_no_grab()
	print("\n".join(results))
	print("\n%d failed" % failures)
	quit(failures)


# --- Harness -------------------------------------------------------------------

func _start_grounded(x: float, facing := 1) -> void:
	input.load_steps([])
	fighter.respawn(Vector3(x, 0.05, 0))
	fighter.facing = facing
	await _frames(12)


func _start_at(pos: Vector3, facing := 1) -> void:
	input.load_steps([])
	fighter.respawn(pos)
	fighter.facing = facing


func _play(steps: Array, frames: int) -> void:
	samples.clear()
	transitions.clear()
	input.load_steps(steps)
	for i in frames:
		await physics_frame
		await process_frame
		samples.append({
			"state": fighter.state,
			"frame": fighter.state_frame,
			"pos": fighter.global_position,
			"vel": fighter.vel,
			"grounded": fighter.is_grounded(),
			"platform": fighter.on_platform != null,
			"fastfall": fighter.fastfalling,
		})


func _frames(n: int) -> void:
	for i in n:
		await physics_frame
	await process_frame


func _max_y() -> float:
	var m := -INF
	for s in samples:
		m = maxf(m, s.pos.y)
	return m


func _visited(state: StringName) -> int:
	for i in samples.size():
		if samples[i].state == state:
			return i
	return -1


func _check(name: String, ok: bool, detail: String) -> void:
	if not ok:
		failures += 1
	results.append("%s  %s  (%s)" % ["PASS" if ok else "FAIL", name, detail])


# --- Cases ----------------------------------------------------------------------

func _case_short_vs_full_hop() -> void:
	await _start_grounded(0)
	await _play([[1, {"jump": true}]], 70)
	var short_h := _max_y()
	await _start_grounded(0)
	await _play([[12, {"jump": true}]], 70)
	var full_h := _max_y()
	_check("Short hop vs full hop", short_h > 0.5 and full_h > short_h * 1.5,
		"short %.2f m, full %.2f m" % [short_h, full_h])


func _case_double_jump() -> void:
	await _start_grounded(0)
	await _play([[12, {"jump": true}], [16, {}], [1, {"jump": true}]], 90)
	var h := _max_y()
	_check("Double jump goes higher than full hop", h > 4.0, "peak %.2f m" % h)


func _case_run() -> void:
	await _start_grounded(-6)
	await _play([[40, {"x": 1.0}]], 40)
	var last: Dictionary = samples[-1]
	_check("Hold forward: dash into run", last.state == &"run" and last.vel.x > fighter.stats.run_max * 0.95,
		"state %s, speed %.2f" % [last.state, last.vel.x])


func _case_dash_dance() -> void:
	await _start_grounded(0)
	var steps := []
	for i in 4:
		steps.append([6, {"x": 1.0}])
		steps.append([6, {"x": -1.0}])
	await _play(steps, 48)
	var dashes := 0
	var ran := false
	for t in transitions:
		if t[1] == &"dash":
			dashes += 1
		if t[1] == &"run":
			ran = true
	var drift: float = absf(samples[-1].pos.x)
	_check("Dash dance turns instantly", dashes >= 8 and not ran and drift < 1.5,
		"%d dashes, never ran: %s, drift %.2f m" % [dashes, not ran, drift])


func _case_wavedash() -> void:
	await _start_grounded(-4)
	await _play([[1, {"jump": true}], [2, {}], [1, {"x": 1.0, "y": -0.3, "dodge": true}], [3, {"x": 1.0, "y": -0.3}], [40, {}]], 47)
	var land_i := _visited(&"landing")
	var dist: float = samples[-1].pos.x - (-4.0)
	var peak := _max_y()
	_check("Wavedash slides along the ground", land_i >= 0 and land_i < 10 and dist > 1.5 and peak < 0.3,
		"landed frame %d, slide %.2f m, peak height %.2f m" % [land_i, dist, peak])


func _case_fast_fall() -> void:
	await _start_grounded(0)
	await _play([[12, {"jump": true}], [24, {}], [3, {"y": -1.0}], [3, {}]], 42)
	var ff := false
	var speed := 0.0
	for s in samples:
		if s.fastfall:
			ff = true
			speed = -s.vel.y
	_check("Flick down after the peak fast falls", ff and is_equal_approx(speed, fighter.stats.fast_fall),
		"fast falling %s at %.2f units/frame" % [ff, speed])


func _case_platform_land_and_drop() -> void:
	await _start_grounded(-3.8)
	await _play([[12, {"jump": true}], [70, {}]], 82)
	var on_plat: bool = samples[-1].platform
	var y_on: float = samples[-1].pos.y
	await _play([[2, {}], [1, {"y": -1.0}], [60, {}]], 63)
	var y_after: float = samples[-1].pos.y
	_check("Land on a platform, flick down to drop", on_plat and absf(y_on - 2.7) < 0.05 and absf(y_after) < 0.05,
		"on platform %s at y %.2f, after drop y %.2f" % [on_plat, y_on, y_after])


func _case_ledge_grab_and_getup() -> void:
	await _start_at(Vector3(8.5, -0.9, 0), -1)
	await _play([[20, {}]], 20)
	var grabbed := _visited(&"ledge_hang") >= 0
	await _play([[40, {"x": -1.0}]], 50)
	var last: Dictionary = samples[-1]
	_check("Grab ledge, get up onto stage", grabbed and last.grounded and last.pos.x < 8.0,
		"grabbed %s, ended %s at x %.2f" % [grabbed, last.state, last.pos.x])


func _case_ledge_roll() -> void:
	await _start_at(Vector3(8.5, -0.9, 0), -1)
	await _play([[12, {}], [1, {"dodge": true}], [50, {}]], 63)
	var last: Dictionary = samples[-1]
	_check("Ledge roll lands further in", last.grounded and last.pos.x < 6.5,
		"ended %s at x %.2f" % [last.state, last.pos.x])


func _case_ledge_dash() -> void:
	await _start_at(Vector3(8.5, -0.9, 0), -1)
	# hang, drop, double jump, airdodge toward the stage
	await _play([[10, {}], [1, {"x": 1.0}], [2, {}], [1, {"jump": true}], [9, {}],
		[1, {"x": -1.0, "y": -0.25, "dodge": true}], [40, {}]], 64)
	var waveland := false
	for t in transitions:
		if t[0] == &"airdodge" and t[1] == &"landing":
			waveland = true
	var last: Dictionary = samples[-1]
	_check("Ledge dash: drop, jump, airdodge onto stage", waveland and last.pos.x < 7.0 and last.grounded,
		"wavelanded %s, ended x %.2f" % [waveland, last.pos.x])


func _case_ledge_cancel() -> void:
	await _start_grounded(7.2)
	await _play([[1, {"jump": true}], [2, {}], [1, {"x": 1.0, "y": -0.3, "dodge": true}], [3, {"x": 1.0, "y": -0.3}], [12, {}]], 19)
	var cancelled := false
	var lag_frames := -1
	for t in transitions:
		if t[0] == &"landing" and t[1] == &"airborne":
			cancelled = true
			lag_frames = t[2]
	_check("Wavedash off the edge cancels landing lag", cancelled and lag_frames < fighter.stats.wavedash_lag,
		"left the stage on landing-lag frame %d of %d" % [lag_frames, fighter.stats.wavedash_lag])


func _case_run_off_no_grab() -> void:
	await _start_grounded(5.0)
	await _play([[50, {"x": 1.0}]], 50)
	_check("Running off forward doesn't snap to the ledge", _visited(&"ledge_hang") == -1 and samples[-1].pos.x > 8.5,
		"ended %s at x %.2f" % [samples[-1].state, samples[-1].pos.x])
