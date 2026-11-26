class_name ScriptedInput
extends InputSource
## Plays back a fixed list of inputs. Used by automated tests, and a handy
## base for recording / replaying inputs while tuning.
##
## Script format: an array of [frames, {"x": float, "y": float, "jump": bool, "dodge": bool}]
## Each step holds those inputs for that many frames. Missing keys = neutral / released.

var steps: Array = []
var _step := 0
var _left := 0
var _current := {}


func _init(script_steps: Array = []) -> void:
	super()
	load_steps(script_steps)


func load_steps(script_steps: Array) -> void:
	steps = script_steps
	_step = 0
	_left = 0
	_current = {}


func finished() -> bool:
	return _step >= steps.size() and _left <= 0


func _advance() -> void:
	while _left <= 0 and _step < steps.size():
		_left = steps[_step][0]
		_current = steps[_step][1]
		_step += 1
	if _left <= 0:
		_current = {}
	_left -= 1


func _read_stick() -> Vector2:
	_advance()
	return Vector2(_current.get("x", 0.0), _current.get("y", 0.0))


func _read_buttons() -> int:
	var b := 0
	if _current.get("jump", false): b |= Btn.JUMP
	if _current.get("dodge", false): b |= Btn.DODGE
	if _current.get("attack", false): b |= Btn.ATTACK
	if _current.get("special", false): b |= Btn.SPECIAL
	if _current.get("grab", false): b |= Btn.GRAB
	return b
