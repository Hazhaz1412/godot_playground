extends CharacterBody3D

const SPEED = 3.0
const JUMP_VELOCITY = 4.5
const DODGE_SPEED = 2.0

@onready var anim = $AnimationPlayer
@onready var visuals = $player

var idle_timer := 0.0
var wait_time := 6.0

# --- COMBAT ---
var is_attacking := false
var combo_step := 0
var combo_queued := false

# --- DODGE ---
var is_dodging := false
var dodge_dir := Vector3.ZERO
var invincible := false

# --- STATS ---
var health := 100


func _ready():
	anim.play("Global/idle4")
	randomize_wait_time()


func _physics_process(delta):

	# =========================
	# GRAVITY
	# =========================
	if not is_on_floor():
		velocity += get_gravity() * delta


	# =========================
	# INPUT
	# =========================

	if Input.is_action_just_pressed("dodge") \
	and is_on_floor() \
	and not is_dodging \
	and not is_attacking:
		start_dodge()

	if Input.is_action_just_pressed("attack") and is_on_floor():

		if not is_attacking and not is_dodging:
			start_attack()

		elif is_attacking:
			var pos = anim.current_animation_position
			var len = anim.current_animation_length

			if pos > len * 0.55:
				combo_queued = true


	# =========================
	# STATE PRIORITY
	# =========================

	if is_dodging:

		var progress = anim.current_animation_position / anim.current_animation_length

		var speed_factor := 1.0

		if progress > 0.6:
			speed_factor = lerp(1.0,0.0,(progress - 0.6)/0.4)

		velocity.x = dodge_dir.x * DODGE_SPEED * speed_factor
		velocity.z = dodge_dir.z * DODGE_SPEED * speed_factor

		move_and_slide()
		return


	if is_attacking:

		var pos = anim.current_animation_position
		var len = anim.current_animation_length
		var progress = pos / len

		if combo_queued and progress > 0.85:

			combo_queued = false
			combo_step += 1

			match combo_step:
				2:
					anim.play("Global/slash3",0.15)
				3:
					anim.play("Global/slash2_p1",0.15)
				4:
					anim.play("Global/slash2_p3",0.15)

		velocity.x = move_toward(velocity.x,0,SPEED)
		velocity.z = move_toward(velocity.z,0,SPEED)

		move_and_slide()
		return


	# =========================
	# NORMAL MOVEMENT
	# =========================

	var input_dir := Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_backward"
	)

	var cam_basis: Basis = $CameraMount/h.global_transform.basis

	var direction: Vector3 = (
		cam_basis * Vector3(input_dir.x,0,input_dir.y)
	).normalized()

	var just_jumped := false


	# =========================
	# JUMP
	# =========================

	if Input.is_action_just_pressed("jump") and is_on_floor():

		velocity.y = JUMP_VELOCITY
		just_jumped = true

		if direction != Vector3.ZERO:
			anim.play("Global/jump",0.1)
		else:
			anim.play("Global/jump2",0.1)


	# =========================
	# MOVE
	# =========================

	if direction:

		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED

		idle_timer = 0

		if is_on_floor() and not just_jumped and anim.current_animation != "Global/run":
			anim.play("Global/run",0.15)

		var target_angle = atan2(direction.x,direction.z)

		visuals.rotation.y = lerp_angle(
			visuals.rotation.y,
			target_angle,
			10 * delta
		)

	else:

		velocity.x = move_toward(velocity.x,0,SPEED)
		velocity.z = move_toward(velocity.z,0,SPEED)

		if is_on_floor() and not just_jumped and not "idle" in anim.current_animation:
			anim.play("Global/idle4",0.2)


	move_and_slide()


	# =========================
	# RANDOM IDLE
	# =========================

	if direction == Vector3.ZERO and is_on_floor() and not just_jumped:

		if anim.current_animation == "Global/idle4":

			idle_timer += delta

			if idle_timer >= wait_time:
				play_random_idle()



# =========================
# ATTACK
# =========================

func start_attack():

	is_attacking = true
	combo_step = 1
	combo_queued = false

	anim.play("Global/slash2_p1",0.15)



# =========================
# DODGE
# =========================

func start_dodge():

	is_dodging = true
	invincible = false

	anim.play("Global/roll1",0.1)

	var input_dir := Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_backward"
	)

	var cam_basis: Basis = $CameraMount/h.global_transform.basis

	if input_dir.length() < 0.1:
		# backstep nếu không có input
		dodge_dir = -visuals.global_transform.basis.z
	else:
		dodge_dir = (
			cam_basis * Vector3(input_dir.x,0,input_dir.y)
		)

	dodge_dir = dodge_dir.normalized()

	# xoay body theo hướng roll
	var angle = atan2(dodge_dir.x,dodge_dir.z)
	visuals.rotation.y = angle



func enable_iframe():
	invincible = true


func disable_iframe():
	invincible = false


func end_dodge():

	is_dodging = false
	invincible = false



# =========================
# DAMAGE
# =========================

func take_damage(dmg):

	if invincible:
		return

	health -= dmg
	print("HP:",health)



# =========================
# RANDOM IDLE
# =========================

func play_random_idle():

	idle_timer = 0
	randomize_wait_time()

	var random_anims = [
		"Global/idle2",
		"Global/idle3"
	]

	anim.play(random_anims.pick_random(),0.2)
	anim.queue("Global/idle4")


func randomize_wait_time():
	wait_time = randf_range(6.0,7.0)



# =========================
# ANIMATION FINISHED
# =========================

func _on_animation_player_animation_finished(anim_name):

	if "slash" in anim_name:

		if combo_queued:
			return

		is_attacking = false
		combo_step = 0
		combo_queued = false

		anim.play("Global/idle4",0.2)

	if "roll" in anim_name:
		end_dodge()
