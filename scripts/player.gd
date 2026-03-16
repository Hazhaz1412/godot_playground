extends CharacterBody3D

# --- CẤU HÌNH CƠ BẢN ---
const SPEED = 1.5
const JUMP_VELOCITY = 3.5
const DODGE_SPEED = 1.75

# --- REFERENCES (KIỂM TRA ĐƯỜNG DẪN NODE TẠI ĐÂY) ---
@onready var anim = $AnimationPlayer
@onready var visuals = $player
# Đường dẫn tới cái Node GPUParticles3D bác vừa tạo
@onready var sword_trail = $"player/Skeleton3D/BoneAttachment3D/Espada PS1/BladeTrail_VFX"

# --- BIẾN ĐIỀU KHIỂN ---
var idle_timer := 0.0
var wait_time := 6.0

# --- COMBAT ---
var is_attacking := false
var combo_step := 0
var combo_queued := false
var attack_locked := false

# --- DODGE ---
var is_dodging := false
var dodge_dir := Vector3.ZERO
var invincible := false

# --- STATS ---
var health := 100
var fp := 50
var stamina := 120

func _ready():
	anim.play("idle4")
	randomize_wait_time()
	# Mới vào game thì tắt hiệu ứng đi cho chắc
	if sword_trail: sword_trail.emitting = false

func _physics_process(delta):
	# =========================
	# TRỌNG LỰC
	# =========================
	if not is_on_floor():
		velocity += get_gravity() * delta

	# =========================
	# XỬ LÝ INPUT
	# =========================
	if Input.is_action_just_pressed("dodge") and is_on_floor() and not is_dodging and not is_attacking:
		start_dodge()

	if Input.is_action_just_pressed("attack") and is_on_floor():
		if not is_attacking and not is_dodging:
			start_attack()
		elif is_attacking:
			var pos = anim.current_animation_position
			var len = anim.current_animation_length
			# Cho phép bấm bồi combo khi đã múa được hơn nửa animation
			if pos > len * 0.55:
				combo_queued = true

	# =========================
	# TRẠNG THÁI ƯU TIÊN (DODGE/ATTACK)
	# =========================

	# 1. Logic Né (Dodge)
	if is_dodging:
		var progress = anim.current_animation_position / anim.current_animation_length
		var speed_factor := 1.0
		if progress > 0.6:
			speed_factor = lerp(1.0, 0.0, (progress - 0.6) / 0.4)
		velocity.x = dodge_dir.x * DODGE_SPEED * speed_factor
		velocity.z = dodge_dir.z * DODGE_SPEED * speed_factor
		move_and_slide()
		return

	# 2. Logic Tấn công (Attack)
	if is_attacking:
		var pos = anim.current_animation_position
		var len = anim.current_animation_length
		var progress = pos / len

		var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
		var cam_basis: Basis = $CameraMount/h.global_transform.basis
		var direction: Vector3 = (cam_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

		# Startup turning (Xoay người hướng về phía input lúc mới bắt đầu chém)
		if progress < 0.2 and direction != Vector3.ZERO:
			var angle = atan2(direction.x, direction.z)
			visuals.rotation.y = lerp_angle(visuals.rotation.y, angle, 12 * delta)
		else:
			attack_locked = true

		# Hệ thống Combo + Bật VFX
		if combo_queued and progress > 0.85:
			combo_queued = false
			combo_step += 1
			
			# Mỗi lần sang nhát chém mới, đảm bảo VFX được bật lại
			if sword_trail: sword_trail.emitting = true 

			match combo_step:
				2: anim.play("slash3", 0.15)
				3: anim.play("slash", 0.15)
				4: anim.play("attack2", 0.15)

		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		move_and_slide()
		return

	# =========================
	# DI CHUYỂN BÌNH THƯỜNG
	# =========================
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var cam_basis: Basis = $CameraMount/h.global_transform.basis
	var direction: Vector3 = (cam_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var just_jumped := false

	# Nhảy
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		just_jumped = true
		if direction != Vector3.ZERO:
			anim.play("jump", 0.1)
		else:
			anim.play("jump2", 0.1)

	# Di chuyển & Xoay nhân vật
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		idle_timer = 0
		if is_on_floor() and not just_jumped and anim.current_animation != "run":
			anim.play("run", 0.15)
		var target_angle = atan2(direction.x, direction.z)
		visuals.rotation.y = lerp_angle(visuals.rotation.y, target_angle, 10 * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		if is_on_floor() and not just_jumped and not "idle" in anim.current_animation:
			anim.play("idle4", 0.2)

	move_and_slide()

	# Random Idle Logic
	if direction == Vector3.ZERO and is_on_floor() and not just_jumped:
		if anim.current_animation == "idle4":
			idle_timer += delta
			if idle_timer >= wait_time:
				play_random_idle()

# =========================
# CÁC HÀM XỬ LÝ CHI TIẾT
# =========================

func start_attack():
	is_attacking = true
	combo_step = 1
	combo_queued = false
	attack_locked = false
	
	# Bật vệt sáng cho nhát chém đầu tiên
	if sword_trail: sword_trail.emitting = true 
	anim.play("slash", 0.15)

func start_dodge():
	is_dodging = true
	invincible = false
	anim.play("roll1", 0.1)

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var cam_basis: Basis = $CameraMount/h.global_transform.basis

	if input_dir.length() < 0.1:
		# dodge forward nếu không bấm gì
		dodge_dir = (-visuals.global_transform.basis.z).normalized()
	else:
		dodge_dir = (cam_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	visuals.rotation.y = atan2(dodge_dir.x, dodge_dir.z)

func enable_iframe(): invincible = true
func disable_iframe(): invincible = false
func end_dodge():
	is_dodging = false
	invincible = false

func take_damage(dmg):
	if invincible: return
	health -= dmg
	print("HP:", health)

func play_random_idle():
	idle_timer = 0
	randomize_wait_time()
	var random_anims = ["idle2", "idle3"]
	anim.play(random_anims.pick_random(), 0.2)
	anim.queue("idle4")

func randomize_wait_time():
	wait_time = randf_range(6.0, 7.0)

# =========================
# KHI ANIMATION KẾT THÚC
# =========================

func _on_animation_player_animation_finished(anim_name):
	if is_attacking:
		# Nếu đang nối combo thì không dừng trạng thái đánh
		if combo_queued:
			return
		
		# Kết thúc chuỗi combo -> Tắt VFX
		is_attacking = false
		combo_step = 0
		combo_queued = false
		if sword_trail: sword_trail.emitting = false 
		anim.play("idle4", 0.2)

	if "roll" in anim_name:
		end_dodge()
