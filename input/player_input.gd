class_name PlayerInput
extends InputSource
## Reads the keyboard or a gamepad through the actions in InputSetup.

func _read_stick() -> Vector2:
	var s := Input.get_vector("move_left", "move_right", "move_down", "move_up", DEADZONE)
	if Input.is_action_pressed("walk_mod"):
		s *= 0.5  # keyboard walk: stays under the flick threshold
	return s


func _read_buttons() -> int:
	var b := 0
	if Input.is_action_pressed("jump"): b |= Btn.JUMP
	if Input.is_action_pressed("dodge"): b |= Btn.DODGE
	if Input.is_action_pressed("attack"): b |= Btn.ATTACK
	if Input.is_action_pressed("special"): b |= Btn.SPECIAL
	if Input.is_action_pressed("grab"): b |= Btn.GRAB
	return b
