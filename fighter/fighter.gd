class_name Fighter
extends CharacterBody3D
## Platform-fighter movement on a 2D plane (x = horizontal, y = up, z locked).
##
## Each physics tick (60/s): poll input -> run the current state -> move ->
## react to landing or leaving the ground. Every state is a pair of methods,
## _enter_<name>() (optional) and _tick_<name>(), so adding a state means
## adding two functions. Attacks come later as data that one "attack" state
## plays back, so this movement list should stay short.
##
## Velocity is kept in Melee units per frame (see FighterStats).

signal state_changed(from: StringName, to: StringName)
signal landed(kind: StringName)

const UNIT := 0.1  # meters per Melee unit
const GROUND_STICK := -1.0  # m/s pushed into the floor so the fighter notices walking off edges

const AIR_STATES := [&"airborne", &"airdodge", &"helpless"]
const GROUND_STATES := [&"idle", &"walk", &"dash", &"run", &"run_brake", &"run_turn", &"jumpsquat", &"landing"]
const LEDGE_STATES := [&"ledge_hang", &"ledge_getup", &"ledge_roll"]

@export var stats: FighterStats
@export_enum("Left:-1", "Right:1") var facing := 1
## Player fighters create a PlayerInput on ready. Tests and AI assign `input` themselves.
@export var use_player_input := true

var input: InputSource
var state: StringName = &"airborne"
var state_frame := 0
var vel := Vector2.ZERO  # units/frame
var jumps_left := 1
var airdodge_available := true
var fastfalling := false
var intangible_frames := 0
var on_platform: Platform = null
var platform_drop_timer := 0
var ledge: Ledge = null
var touched_ground_since_ledge := true
var history: Array = []  # recent [state, frames] pairs for the debug overlay

var _ledge_cooldowns := {}
var _jumpsquat_dodge := false
var _landing_lag := 0
var _move_from := Vector3.ZERO
var _move_to := Vector3.ZERO
var _turned := false

@onready var _visual: Node3D = get_node_or_null("Visual")
@onready var _body_mat: StandardMaterial3D = _find_body_material()


func _ready() -> void:
	if stats == null:
		stats = FighterStats.new()
	if input == null and use_player_input:
		input = PlayerInput.new()
	jumps_left = stats.air_jumps
	floor_snap_length = 0.25
	floor_stop_on_slope = true
	floor_max_angle = deg_to_rad(50)


func _physics_process(_delta: float) -> void:
	if input == null:
		return
	tick()


## One frame of simulation. Public so tests can step it directly.
func tick() -> void:
	input.poll()
	state_frame += 1
	if intangible_frames > 0:
		intangible_frames -= 1
	if platform_drop_timer > 0:
		platform_drop_timer -= 1
	for l in _ledge_cooldowns.keys():
		_ledge_cooldowns[l] -= 1
		if _ledge_cooldowns[l] <= 0:
			_ledge_cooldowns.erase(l)

	call(&"_tick_" + state)

	if state in LEDGE_STATES:
		velocity = Vector3.ZERO
	else:
		_move()
	_update_visual()


func is_grounded() -> bool:
	return is_on_floor() or on_platform != null


func is_intangible() -> bool:
	return intangible_frames > 0


func feet_y() -> float:
	return global_position.y


func change_state(s: StringName) -> void:
	var from := state
	history.push_front([from, state_frame])
	if history.size() > 6:
		history.pop_back()
	state = s
	state_frame = 0
	var enter := &"_enter_" + s
	if has_method(enter):
		call(enter)
	state_changed.emit(from, s)


func respawn(at: Vector3) -> void:
	_release_ledge(false)
	global_position = at
	vel = Vector2.ZERO
	velocity = Vector3.ZERO
	on_platform = null
	fastfalling = false
	jumps_left = stats.air_jumps
	airdodge_available = true
	change_state(&"airborne")


# =============================================================================
# Motion and collision
# =============================================================================

func _move() -> void:
	var prev_feet := feet_y()
	var grounded_before := is_grounded()
	var motion := Vector3(vel.x, vel.y, 0.0) * UNIT * 60.0
	if state in GROUND_STATES and vel.y <= 0.0:
		motion.y = GROUND_STICK
	velocity = motion
	move_and_slide()
	global_position.z = 0.0

	# Walls and ceilings stop our stored velocity too.
	if is_on_wall():
		var n := get_wall_normal()
		if n.x * vel.x < 0.0:
			vel.x = 0.0
	if is_on_ceiling() and vel.y > 0.0:
		vel.y = 0.0

	_resolve_platforms(prev_feet)

	var grounded := is_grounded()
	if grounded:
		touched_ground_since_ledge = true
	if state in AIR_STATES and grounded and vel.y <= 0.0:
		_land()
	elif state in GROUND_STATES and grounded_before and not grounded:
		_leave_ground()


func _resolve_platforms(prev_feet: float) -> void:
	if vel.y > 0.0 or platform_drop_timer > 0:
		on_platform = null
		return
	var x := global_position.x
	# Stay on the platform we're standing on while we're over it.
	if on_platform != null:
		if x >= on_platform.left() and x <= on_platform.right() and not is_on_floor():
			global_position.y = on_platform.top()
			return
		on_platform = null
	if is_on_floor():
		return
	# Land on a platform if our feet crossed its top this frame.
	for p: Platform in get_tree().get_nodes_in_group(&"platforms"):
		if x < p.left() or x > p.right():
			continue
		var top := p.top()
		if prev_feet >= top - 0.01 and feet_y() <= top:
			global_position.y = top
			on_platform = p
			return


func _land() -> void:
	var kind := &"normal"
	if state == &"airdodge":
		kind = &"wavedash"
		vel.x *= stats.wavedash_speed_mult
		_landing_lag = stats.wavedash_lag
	elif state == &"helpless":
		kind = &"helpless"
		_landing_lag = stats.helpless_landing_lag
	else:
		_landing_lag = stats.landing_lag
	vel.y = 0.0
	fastfalling = false
	jumps_left = stats.air_jumps
	airdodge_available = true
	change_state(&"landing")
	landed.emit(kind)


## Walked, dashed or slid off an edge. Leaving during landing lag cancels the
## lag entirely: that's the ledge cancel.
func _leave_ground() -> void:
	vel.y = 0.0
	on_platform = null
	change_state(&"airborne")


func _apply_traction() -> void:
	var t := stats.traction * (2.0 if absf(vel.x) > stats.walk_max else 1.0)
	vel.x = move_toward(vel.x, 0.0, t)


func _stick() -> Vector2:
	return input.stick()


# =============================================================================
# Ground states
# =============================================================================

## Actions available from most grounded states. Returns true if it changed state.
func _ground_actions() -> bool:
	if input.buffered(InputSource.Btn.JUMP, stats.input_buffer):
		input.consume(InputSource.Btn.JUMP)
		change_state(&"jumpsquat")
		return true
	if on_platform != null and input.flick_y() == -1:
		platform_drop_timer = stats.platform_drop_frames
		on_platform = null
		vel.y = -0.5
		change_state(&"airborne")
		return true
	return false


func _tick_idle() -> void:
	_apply_traction()
	if _ground_actions():
		return
	var fx := input.flick_x()
	if fx != 0:
		facing = fx
		change_state(&"dash")
		return
	var sx := _stick().x
	if absf(sx) >= stats.walk_threshold:
		facing = int(signf(sx))
		change_state(&"walk")


func _tick_walk() -> void:
	if _ground_actions():
		return
	var fx := input.flick_x()
	if fx != 0:
		facing = fx
		change_state(&"dash")
		return
	var sx := _stick().x
	if absf(sx) < stats.walk_threshold:
		change_state(&"idle")
		return
	facing = int(signf(sx))
	var target := sx * stats.walk_max
	if absf(vel.x) > absf(target) and signf(vel.x) == signf(target):
		_apply_traction()
	else:
		vel.x = move_toward(vel.x, target, stats.walk_accel)


func _enter_dash() -> void:
	var carried := vel.x * facing
	vel.x = facing * maxf(stats.dash_initial, carried)


func _tick_dash() -> void:
	if _ground_actions():
		return
	var fx := input.flick_x()
	if fx == -facing:
		facing = fx  # dash dance: instant turn during the initial dash
		change_state(&"dash")
		return
	var sx := _stick().x
	if absf(sx) >= stats.walk_threshold and signf(sx) == facing:
		vel.x = move_toward(vel.x, facing * stats.run_max, stats.dash_accel)
	else:
		_apply_traction()
	if state_frame >= stats.dash_frames:
		if absf(sx) >= stats.run_hold_threshold and signf(sx) == facing:
			change_state(&"run")
		elif absf(sx) >= stats.run_hold_threshold:
			facing = -facing
			change_state(&"dash")
		else:
			change_state(&"idle")


func _tick_run() -> void:
	if _ground_actions():
		return
	var sx := _stick().x
	if absf(sx) < stats.walk_threshold:
		change_state(&"run_brake")
		return
	if signf(sx) != facing and absf(sx) >= stats.run_hold_threshold:
		change_state(&"run_turn")
		return
	vel.x = move_toward(vel.x, facing * stats.run_max, stats.run_accel)


func _tick_run_brake() -> void:
	_apply_traction()
	if _ground_actions():
		return
	var sx := _stick().x
	if signf(sx) == -facing and absf(sx) >= stats.run_hold_threshold:
		change_state(&"run_turn")
		return
	if state_frame >= stats.run_brake_frames or is_zero_approx(vel.x):
		change_state(&"idle")


func _enter_run_turn() -> void:
	_turned = false


## Skid, flip around once the momentum dies, then accelerate the other way.
func _tick_run_turn() -> void:
	if _ground_actions():
		return
	if not _turned:
		vel.x = move_toward(vel.x, 0.0, stats.traction * 2.0)
		if is_zero_approx(vel.x) or state_frame * 2 >= stats.run_turn_frames:
			facing = -facing
			_turned = true
	else:
		vel.x = move_toward(vel.x, facing * stats.run_max, stats.run_accel)
	if state_frame >= stats.run_turn_frames:
		var sx := _stick().x
		if signf(sx) == facing and absf(sx) >= stats.walk_threshold:
			change_state(&"run")
		else:
			change_state(&"run_brake")


func _enter_jumpsquat() -> void:
	_jumpsquat_dodge = false


func _tick_jumpsquat() -> void:
	_apply_traction()
	if input.buffered(InputSource.Btn.DODGE, stats.input_buffer):
		_jumpsquat_dodge = true
	if state_frame < stats.jump_squat:
		return
	if _jumpsquat_dodge:
		# Airdodge out of jumpsquat replaces the jump. Angled down, it hits the
		# ground next frame: a wavedash.
		_start_airdodge()
		return
	# Release jump before jumpsquat ends = short hop.
	var full := input.held(InputSource.Btn.JUMP)
	vel.y = stats.full_hop if full else stats.short_hop
	vel.x = clampf(vel.x * stats.jump_h_ground_mult + _stick().x * stats.jump_h_stick,
			-stats.jump_h_max, stats.jump_h_max)
	on_platform = null
	change_state(&"airborne")


func _tick_landing() -> void:
	_apply_traction()
	if state_frame >= _landing_lag:
		change_state(&"idle")
		_tick_idle()  # act on the first free frame


# =============================================================================
# Air states
# =============================================================================

func _apply_gravity() -> void:
	if fastfalling:
		vel.y = -stats.fast_fall
	else:
		vel.y = maxf(vel.y - stats.gravity, -stats.max_fall)


func _apply_air_drift(mult := 1.0) -> void:
	var sx := _stick().x
	if absf(sx) >= stats.walk_threshold:
		var target := sx * stats.air_max * mult
		if absf(vel.x) > absf(target) and signf(vel.x) == signf(target):
			vel.x = move_toward(vel.x, target, stats.air_friction)
		else:
			vel.x = move_toward(vel.x, target, stats.air_accel * mult)
	else:
		vel.x = move_toward(vel.x, 0.0, stats.air_friction)


func _tick_airborne() -> void:
	if _try_ledge_grab():
		return
	if not fastfalling and vel.y <= 0.0 and input.flick_y() == -1:
		fastfalling = true
	if jumps_left > 0 and input.buffered(InputSource.Btn.JUMP, stats.input_buffer):
		input.consume(InputSource.Btn.JUMP)
		jumps_left -= 1
		vel.y = stats.double_jump
		vel.x = _stick().x * stats.double_jump_h
		fastfalling = false
		return
	if airdodge_available and input.buffered(InputSource.Btn.DODGE, stats.input_buffer):
		_start_airdodge()
		return
	_apply_gravity()
	_apply_air_drift()


func _start_airdodge() -> void:
	input.consume(InputSource.Btn.DODGE)
	airdodge_available = false
	fastfalling = false
	var s := _stick()
	var dir := s.normalized() if s.length() > 0.3 else Vector2.ZERO
	vel = dir * stats.airdodge_speed
	on_platform = null
	change_state(&"airdodge")


func _tick_airdodge() -> void:
	if state_frame == stats.airdodge_intangible_start:
		intangible_frames = stats.airdodge_intangible_end - stats.airdodge_intangible_start + 1
	if state_frame <= stats.airdodge_move_frames:
		vel *= stats.airdodge_decay
	else:
		_apply_gravity()
		vel.x = move_toward(vel.x, 0.0, stats.air_friction)
	if state_frame >= stats.airdodge_total:
		change_state(&"helpless" if stats.airdodge_helpless else &"airborne")


func _tick_helpless() -> void:
	if _try_ledge_grab():
		return
	_apply_gravity()
	_apply_air_drift(0.6)


# =============================================================================
# Ledge states
# =============================================================================

func _try_ledge_grab() -> bool:
	if vel.y > 0.0:
		return false
	var pos := global_position
	for l: Ledge in get_tree().get_nodes_in_group(&"ledges"):
		if _ledge_cooldowns.has(l):
			continue
		if l.occupied_by != null and l.occupied_by != self:
			continue
		var lp := l.global_position
		var outward := (pos.x - lp.x) * l.facing_out
		var dy := lp.y - pos.y
		# Facing the stage, or already out recovering. Running off forward
		# doesn't snap to the ledge, so you can still drop past it.
		var facing_ok := facing == -l.facing_out or outward >= 0.3
		if facing_ok and outward >= -0.3 and outward <= 0.9 and dy >= 0.4 and dy <= 2.0:
			_grab_ledge(l)
			return true
	return false


func _grab_ledge(l: Ledge) -> void:
	ledge = l
	l.occupied_by = self
	facing = -l.facing_out
	vel = Vector2.ZERO
	fastfalling = false
	jumps_left = stats.air_jumps
	airdodge_available = true
	intangible_frames = stats.ledge_intangible if touched_ground_since_ledge else 0
	touched_ground_since_ledge = false
	global_position = _hang_position(l)
	change_state(&"ledge_hang")


func _hang_position(l: Ledge) -> Vector3:
	return l.global_position + Vector3(l.facing_out * 0.4, -1.4, 0.0)


func _release_ledge(cooldown := true) -> void:
	if ledge == null:
		return
	if ledge.occupied_by == self:
		ledge.occupied_by = null
	if cooldown:
		_ledge_cooldowns[ledge] = stats.ledge_regrab_cooldown
	ledge = null


func _tick_ledge_hang() -> void:
	if state_frame < stats.ledge_catch:
		return
	var s := _stick()
	var toward_stage := -ledge.facing_out
	if input.buffered(InputSource.Btn.JUMP, stats.input_buffer):
		input.consume(InputSource.Btn.JUMP)
		_release_ledge()
		vel = Vector2(toward_stage * 0.6, stats.ledge_jump)
		change_state(&"airborne")
	elif input.buffered(InputSource.Btn.DODGE, stats.input_buffer):
		input.consume(InputSource.Btn.DODGE)
		change_state(&"ledge_roll")
	elif s.x * toward_stage >= 0.5 or s.y >= 0.5:
		change_state(&"ledge_getup")
	elif s.x * toward_stage <= -0.5 or s.y <= -0.5 or state_frame >= stats.ledge_hang_max:
		# Drop. Double jump and airdodge are still available: drop, jump,
		# airdodge onto the stage = ledge dash.
		_release_ledge()
		vel = Vector2.ZERO
		change_state(&"airborne")


func _enter_ledge_getup() -> void:
	_start_ledge_climb(stats.ledge_getup_distance)


func _enter_ledge_roll() -> void:
	_start_ledge_climb(stats.ledge_roll_distance)
	intangible_frames = stats.ledge_roll_frames - 8


func _start_ledge_climb(distance: float) -> void:
	_move_from = global_position
	var lp := ledge.global_position
	_move_to = Vector3(lp.x - ledge.facing_out * distance, lp.y + 0.02, 0.0)


func _tick_ledge_getup() -> void:
	_tick_ledge_climb(stats.ledge_getup_frames)


func _tick_ledge_roll() -> void:
	_tick_ledge_climb(stats.ledge_roll_frames)


## Rise to ledge height in the first half, then move onto the stage.
func _tick_ledge_climb(frames: int) -> void:
	var t := clampf(float(state_frame) / frames, 0.0, 1.0)
	var mid := Vector3(_move_from.x, _move_to.y, 0.0)
	if t < 0.5:
		global_position = _move_from.lerp(mid, t * 2.0)
	else:
		global_position = mid.lerp(_move_to, (t - 0.5) * 2.0)
	if state_frame >= frames:
		_release_ledge(false)
		vel = Vector2.ZERO
		change_state(&"idle")


# =============================================================================
# Visuals (placeholder until Blender models arrive)
# =============================================================================

const STATE_COLORS := {
	&"airdodge": Color(0.35, 0.6, 1.0),
	&"landing": Color(1.0, 0.35, 0.3),
	&"jumpsquat": Color(1.0, 0.75, 0.3),
	&"ledge_hang": Color(1.0, 0.9, 0.3),
	&"ledge_getup": Color(1.0, 0.9, 0.3),
	&"ledge_roll": Color(1.0, 0.9, 0.3),
	&"helpless": Color(0.5, 0.5, 0.5),
	&"dash": Color(0.5, 1.0, 0.6),
	&"run": Color(0.4, 0.85, 0.5),
}
const BASE_COLOR := Color(0.85, 0.85, 0.88)


func _find_body_material() -> StandardMaterial3D:
	var body := get_node_or_null("Visual/Body") as MeshInstance3D
	if body == null:
		return null
	var mat := StandardMaterial3D.new()
	body.material_override = mat
	return mat


func _update_visual() -> void:
	if _visual:
		_visual.scale.x = facing
	if _body_mat:
		var c: Color = STATE_COLORS.get(state, BASE_COLOR)
		if is_intangible():
			c = c.lerp(Color.WHITE, 0.6)
		if fastfalling:
			c = c.darkened(0.3)
		_body_mat.albedo_color = c
