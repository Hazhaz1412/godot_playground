extends CharacterBody3D # Hoặc Node3D

@onready var anim_player = $AnimationPlayer 
var is_armed = false # Biến lưu trạng thái cầm kiếm

# Hàm này tự kích hoạt khi có ai đó bước vào cái vòng tròn 5 mét
func _on_detection_area_body_entered(body): 
	if body.is_in_group("Player"):
		do_draw_sword()
	else:
		print("?")
func do_draw_sword():
	# 1. Phát animation rút kiếm ngay lập tức
	anim_player.play("Mushita/draw_sword")
	
	# 2. Đưa animation Idle vào hàng đợi
	anim_player.queue("Mushita/idle")
	
	# 3. Khóa cờ trạng thái lại
	is_armed = true
