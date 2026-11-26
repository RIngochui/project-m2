extends Node
## Registers every input action in code so the bindings are readable and easy
## to change. Keyboard and any standard gamepad work out of the box.
## GameCube adapter support comes in a later phase; it will add bindings here
## and tune deadzones in PlayerInput, without touching fighter code.

const ACTIONS := {
	"move_left":  {"keys": [KEY_A, KEY_LEFT],  "axis": [JOY_AXIS_LEFT_X, -1.0]},
	"move_right": {"keys": [KEY_D, KEY_RIGHT], "axis": [JOY_AXIS_LEFT_X, 1.0]},
	"move_up":    {"keys": [KEY_W, KEY_UP],    "axis": [JOY_AXIS_LEFT_Y, -1.0]},
	"move_down":  {"keys": [KEY_S, KEY_DOWN],  "axis": [JOY_AXIS_LEFT_Y, 1.0]},
	# Melee layout: X / Y jump, L / R shield-airdodge, Z grab, A attack, B special.
	"jump":     {"keys": [KEY_SPACE, KEY_I], "buttons": [JOY_BUTTON_X, JOY_BUTTON_Y]},
	"dodge":    {"keys": [KEY_SHIFT, KEY_O], "buttons": [JOY_BUTTON_LEFT_SHOULDER, JOY_BUTTON_RIGHT_SHOULDER],
				 "triggers": [JOY_AXIS_TRIGGER_LEFT, JOY_AXIS_TRIGGER_RIGHT]},
	"attack":   {"keys": [KEY_J], "buttons": [JOY_BUTTON_A]},
	"special":  {"keys": [KEY_K], "buttons": [JOY_BUTTON_B]},
	"grab":     {"keys": [KEY_L], "buttons": []},
	# Keyboard only: hold to walk instead of dash (a keyboard can't tilt a stick).
	"walk_mod": {"keys": [KEY_CTRL], "buttons": []},
	# Debug
	"debug_pause":   {"keys": [KEY_P], "buttons": []},
	"debug_step":    {"keys": [KEY_PERIOD], "buttons": []},
	"debug_overlay": {"keys": [KEY_F1], "buttons": []},
	"debug_reset":   {"keys": [KEY_R], "buttons": [JOY_BUTTON_BACK]},
}


func _ready() -> void:
	for action in ACTIONS:
		var def: Dictionary = ACTIONS[action]
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.2)
		for k in def.get("keys", []):
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(action, ev)
		for b in def.get("buttons", []):
			var jb := InputEventJoypadButton.new()
			jb.button_index = b
			InputMap.action_add_event(action, jb)
		if def.has("axis"):
			var jm := InputEventJoypadMotion.new()
			jm.axis = def.axis[0]
			jm.axis_value = def.axis[1]
			InputMap.action_add_event(action, jm)
		for t in def.get("triggers", []):
			var tm := InputEventJoypadMotion.new()
			tm.axis = t
			tm.axis_value = 1.0
			InputMap.action_add_event(action, tm)
