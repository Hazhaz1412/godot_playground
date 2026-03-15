extends Area3D

@export var player: CharacterBody3D

func _on_area_entered(area):

	if area.is_in_group("hitbox"):
		player.take_damage(area.damage)
