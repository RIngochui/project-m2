class_name InputSource
extends RefCounted
## Base class for anything that drives a fighter: the player, a scripted test,
## or (later) enemy AI. Fighters only ever read from an InputSource, so enemies
## can reuse the exact same movement code as the player.
##
## Everything is sampled once per physics tick, so timing is counted in frames
## the way Melee frame data is.

enum Btn { JUMP = 1, DODGE = 2, ATTACK = 4, SPECIAL = 8, GRAB = 16 }
const ALL_BUTTONS := [Btn.JUMP, Btn.DODGE, Btn.ATTACK, Btn.SPECIAL, Btn.GRAB]

## Stick thresholds, in the same 0..1 range as Melee analog values.
const DEADZONE := 0.2
const SMASH_THRESHOLD := 0.8   # stick must pass this to count as a flick
const SMASH_START_MAX := 0.3   # ...starting from inside this, within SMASH_WINDOW frames
const SMASH_WINDOW := 2
const HISTORY := 16

var tick := 0
var _sticks: Array[Vector2] = []
var _buttons: Array[int] = []
var _press_tick := {}
var _consumed_tick := {}


func _init() -> void:
	for b in ALL_BUTTONS:
		_press_tick[b] = -1000
		_consumed_tick[b] = -1000


## Called by the fighter exactly once per tick, before its state logic runs.
func poll() -> void:
	tick += 1
	var s := _read_stick()
	if s.length() < DEADZONE:
		s = Vector2.ZERO
	var held := _read_buttons()
	var prev_held := _buttons[0] if not _buttons.is_empty() else 0
	_sticks.push_front(s)
	_buttons.push_front(held)
	if _sticks.size() > HISTORY:
		_sticks.pop_back()
		_buttons.pop_back()
	for b in ALL_BUTTONS:
		if (held & b) and not (prev_held & b):
			_press_tick[b] = tick


# --- Override in subclasses ---------------------------------------------------

func _read_stick() -> Vector2:
	return Vector2.ZERO


func _read_buttons() -> int:
	return 0


# --- Queries ------------------------------------------------------------------

## Stick with +y = up.
func stick(frames_ago := 0) -> Vector2:
	if frames_ago < _sticks.size():
		return _sticks[frames_ago]
	return Vector2.ZERO


func held(b: int) -> bool:
	return not _buttons.is_empty() and (_buttons[0] & b) != 0


func pressed(b: int) -> bool:
	return _press_tick[b] == tick


## True if the button was pressed within the last `window` frames and that
## press hasn't been used yet. Use consume() once an action acts on it.
func buffered(b: int, window := 1) -> bool:
	var t: int = _press_tick[b]
	return t > tick - window and t > _consumed_tick[b]


func consume(b: int) -> void:
	_consumed_tick[b] = _press_tick[b]


## Flick ("smash input") along x this frame: returns -1, 1, or 0.
## Fires once, on the frame the stick crosses SMASH_THRESHOLD, if it started
## from near neutral within the last SMASH_WINDOW frames. This is what makes
## the fighter dash instead of walk.
func flick_x() -> int:
	return _flick(0)


## Flick along y this frame: -1 = down, 1 = up.
func flick_y() -> int:
	return _flick(1)


func _flick(axis: int) -> int:
	var now: float = stick(0)[axis]
	var prev: float = stick(1)[axis]
	if absf(now) < SMASH_THRESHOLD or (absf(prev) >= SMASH_THRESHOLD and signf(prev) == signf(now)):
		return 0
	for i in range(1, SMASH_WINDOW + 1):
		var past: float = stick(i)[axis]
		if absf(past) <= SMASH_START_MAX or signf(past) != signf(now):
			return int(signf(now))
	return 0
