class_name FighterStats
extends Resource
## Every tunable movement number for one fighter.
##
## Speeds and accelerations use Melee's units per frame, and timings are in
## frames at 60 fps, so community frame data can be compared directly.
## Fighter.UNIT converts units to meters (1 unit = 0.1 m; the capsule is
## 1.6 m, about 16 units tall).
##
## Defaults are a medium-weight brawler: between Mario and Falcon.
## These are starting points for tuning, not Melee's exact values.

@export_group("Walk")
@export var walk_accel := 0.1
@export var walk_max := 1.1
## Ground friction. Doubled while moving faster than walk_max, as in Melee.
## This is what sets wavedash length.
@export var traction := 0.06

@export_group("Dash and run")
@export var dash_initial := 1.6
@export var dash_accel := 0.12
@export var run_max := 1.7
@export var run_accel := 0.12
## Length of the initial dash. A flick back during it turns instantly (dash dance).
@export var dash_frames := 13
@export var run_brake_frames := 18
@export var run_turn_frames := 20

@export_group("Jump")
@export var jump_squat := 4
@export var full_hop := 2.5
@export var short_hop := 1.6
@export var double_jump := 2.3
@export var air_jumps := 1
## Horizontal speed on leaving the ground = ground speed * this + stick x * jump_h_stick.
@export var jump_h_ground_mult := 0.75
@export var jump_h_stick := 0.8
@export var jump_h_max := 1.2
## A double jump sets horizontal speed to stick x * this (it can reverse momentum).
@export var double_jump_h := 0.9

@export_group("Air")
@export var gravity := 0.1
@export var max_fall := 1.8
@export var fast_fall := 2.5
@export var air_accel := 0.06
@export var air_max := 1.0
@export var air_friction := 0.02

@export_group("Airdodge and wavedash")
@export var airdodge_speed := 3.1
## Airdodge speed is multiplied by this every frame of the dodge.
@export var airdodge_decay := 0.9
@export var airdodge_move_frames := 30
@export var airdodge_total := 40
@export var airdodge_intangible_start := 4
@export var airdodge_intangible_end := 29
## Melee puts you in helpless fall after an airdodge. Off by default:
## harsh in a metroidvania with pits everywhere.
@export var airdodge_helpless := false
## Horizontal speed kept when an airdodge hits the ground.
@export var wavedash_speed_mult := 0.8
@export var wavedash_lag := 10

@export_group("Landing")
@export var landing_lag := 4
@export var helpless_landing_lag := 10

@export_group("Ledge")
## Frames after grabbing before you can act.
@export var ledge_catch := 7
@export var ledge_hang_max := 300
## Intangible on grab, only if you touched the ground since the last grab.
@export var ledge_intangible := 30
@export var ledge_regrab_cooldown := 30
@export var ledge_getup_frames := 30
@export var ledge_roll_frames := 40
@export var ledge_jump := 2.6
## Meters.
@export var ledge_getup_distance := 0.7
@export var ledge_roll_distance := 2.0

@export_group("Platforms")
## Frames platforms are ignored after dropping through one.
@export var platform_drop_frames := 10

@export_group("Input")
## Frames a jump or airdodge press is remembered. Melee has none; a small
## buffer makes the game friendlier without changing the tech.
@export var input_buffer := 3
## Stick x needed to walk, and to turn a run around.
@export var walk_threshold := 0.25
@export var run_hold_threshold := 0.6
