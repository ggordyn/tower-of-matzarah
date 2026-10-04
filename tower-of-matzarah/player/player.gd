extends CharacterBody3D
## First-person capsule: WASD to move, mouse to look, Esc to free the mouse,
## click to recapture it.

@export var move_speed := 5.0
@export var mouse_sensitivity := 0.002
## How far you can look up/down, in degrees. Just under 90 avoids flipping.
@export var max_pitch_degrees := 89.0

## Server movement check: each player has a distance budget that refills at
## move_speed × tolerance per second and is spent by every update. The cap lets
## bunched-up updates through but can't be saved up for a teleport.
const MOVE_CHECK_TOLERANCE := 1.25
const MOVE_BUDGET_CAP := 1.0

## Remembered at spawn: by the time this node leaves the tree after a
## disconnect, the session is gone and is_multiplayer_authority() is unreliable.
var _is_local := false

# Server only: movement check state.
var _last_valid_position := Vector3.ZERO
var _last_check_msec := 0
var _move_budget := MOVE_BUDGET_CAP

@onready var _head: Node3D = $Head
@onready var _camera: Camera3D = $Head/Camera3D
@onready var _body: MeshInstance3D = $Body
@onready var _visor: MeshInstance3D = $Body/Visor
@onready var _synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer


func _enter_tree() -> void:
	# The node is named after its owner's peer ID, so every machine agrees on
	# the owner without extra messages. Runs before _ready() and before the
	# MultiplayerSynchronizer starts sending.
	set_multiplayer_authority(name.to_int())


func _ready() -> void:
	# The host checks every client-owned player's movement as updates arrive.
	if multiplayer.is_server() and not is_multiplayer_authority():
		_last_valid_position = position
		_last_check_msec = Time.get_ticks_msec()
		_synchronizer.synchronized.connect(_check_movement)

	if not is_multiplayer_authority():
		# Someone else's player: no input, no physics. The synchronizer moves it.
		set_physics_process(false)
		set_process_unhandled_input(false)
		return

	_is_local = true
	_apply_debug_speed_override()
	_camera.current = true
	# You see your own shadow, but not the inside of your own capsule.
	# cast_shadow doesn't pass down to children, so the visor needs it too.
	_body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	_visor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _apply_debug_speed_override() -> void:
	# Debug builds only: `--debug-speed=X` after `--` fakes a speed cheat on
	# this instance's own player, to test the host's movement check.
	if not OS.is_debug_build():
		return
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--debug-speed="):
			move_speed = arg.get_slice("=", 1).to_float()


func _exit_tree() -> void:
	# Hand the mouse back (e.g. returning to the menu after the host leaves).
	if _is_local:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _check_movement() -> void:
	# Runs on the host right after a new position from the owner was applied.
	var now := Time.get_ticks_msec()
	var elapsed := (now - _last_check_msec) / 1000.0
	_last_check_msec = now
	# Refill the budget with the distance a legal player could cover since the
	# last update, never above the cap.
	_move_budget = minf(_move_budget + move_speed * MOVE_CHECK_TOLERANCE * elapsed, MOVE_BUDGET_CAP)

	var moved := Vector2(position.x - _last_valid_position.x, position.z - _last_valid_position.z).length()
	if moved <= _move_budget:
		_move_budget -= moved
		_last_valid_position = position
		return

	push_warning("[Server] Player %s moved %.2f m with %.2f m of budget left; correcting." % [name, moved, _move_budget])
	position = _last_valid_position
	# Only the offending player needs to know.
	_correct_position.rpc_id(get_multiplayer_authority(), _last_valid_position)


# "any_peer" because this node's authority is the client, so "authority" mode
# would only let the client call it. We check the sender ourselves instead.
@rpc("any_peer", "call_remote", "reliable")
func _correct_position(valid_position: Vector3) -> void:
	if multiplayer.get_remote_sender_id() != 1:
		return  # only the host may correct us
	position = valid_position
	velocity = Vector3.ZERO


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# Yaw turns the whole body, so "forward" follows where you look.
		rotate_y(-event.relative.x * mouse_sensitivity)
		# Pitch tilts only the head; clamped so you can't look past straight up/down.
		_head.rotate_x(-event.relative.y * mouse_sensitivity)
		var max_pitch := deg_to_rad(max_pitch_degrees)
		_head.rotation.x = clampf(_head.rotation.x, -max_pitch, max_pitch)
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	# x = left/right, y = forward/back (forward is negative, matching Godot's -Z forward).
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	# Turn the input into a world direction relative to where the body faces.
	var direction := (transform.basis * Vector3(input.x, 0.0, input.y)).normalized()
	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed

	move_and_slide()
