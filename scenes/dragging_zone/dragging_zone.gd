extends Area2D

func _on_mouse_entered() -> void:
	Dragging.dragging_zones.append(self)


func _on_mouse_exited() -> void:
	Dragging.dragging_zones.erase(self)
