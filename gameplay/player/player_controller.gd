extends CharacterBody3D
## Camera-relative movement. The imported model and its animations remain scenes/resources.

@export var speed: float = 3.2
@export var run_speed: float = 5.6
@export var acceleration: float = 18.0
@export var turn_speed: float = 12.0

@onready var visual: Node3D = $Visual
@onready var animator: AnimationPlayer = $AnimationPlayer
var _spawn: Vector3
var _animation: StringName

func _ready() -> void:
	_spawn = global_position
	# Loop private copies, leaving the imported animation libraries untouched.
	var locomotion := AnimationLibrary.new()
	for pair in [["idle", "General/Idle_A"], ["walk", "MovementBasic/Walking_B"], ["run", "MovementBasic/Running_A"]]:
		var clip := animator.get_animation(pair[1]).duplicate() as Animation
		clip.loop_mode = Animation.LOOP_LINEAR
		locomotion.add_animation(pair[0], clip)
	animator.add_animation_library("Locomotion", locomotion)
	_play(&"idle")

func _physics_process(delta: float) -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var running := Input.is_action_pressed("run") and input.length_squared() > 0.01
	var movement_speed := run_speed if running else speed
	var camera := get_viewport().get_camera_3d()
	var right := Vector3.RIGHT
	var down := Vector3.BACK
	if camera:
		right = camera.global_basis.x
		down = camera.global_basis.z
		right.y = 0.0
		down.y = 0.0
		right = right.normalized()
		down = down.normalized()
	var direction := right * input.x + down * input.y
	velocity.x = move_toward(velocity.x, direction.x * movement_speed, acceleration * delta)
	velocity.z = move_toward(velocity.z, direction.z * movement_speed, acceleration * delta)
	if not is_on_floor():
		velocity += get_gravity() * delta
	move_and_slide()
	if direction.length_squared() > 0.01:
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(direction.x, direction.z), 1.0 - exp(-turn_speed * delta))
	var moving := Vector2(velocity.x, velocity.z).length() > 0.1
	_play((&"run" if running else &"walk") if moving else &"idle")
	if global_position.y < -5.0:
		global_position = _spawn
		velocity = Vector3.ZERO
		reset_physics_interpolation()

func _play(state: StringName) -> void:
	if _animation == state:
		return
	_animation = state
	animator.play("Locomotion/" + state, 0.18)
