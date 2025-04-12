extends "res://scenes/dragging_zone/dragging_zone.gd"

func update_drawer_position():
	var groups = get_groups()
	var i = groups.find_custom(func(name: StringName): return name.begins_with("drawer_"))
	if i == -1:
		return
	var drawer_group = groups[i]
	get_tree().call_group(drawer_group, "move", Vector2(10, 10))

func move(vector: Vector2):
	global_position += vector

func _on_button_pressed() -> void:
	update_drawer_position()
