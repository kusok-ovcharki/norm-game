extends Control


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/DialogScene.tscn")


func _on_h_slider_value_changed(value: float) -> void:
	Settings.change_volume(value)
