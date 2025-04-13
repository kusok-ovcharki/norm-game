extends Control

var is_waiting_for_input := false
var current_position = 0

func _ready():
	$AnimationPlayer.play("fox")

# Метод, который будет вызван через AnimationPlayer
func pause_animation():
	is_waiting_for_input = true
	# Приостанавливаем анимацию
	current_position = $AnimationPlayer.current_animation_position
	$AnimationPlayer.pause()  

func _on_margin_container_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
			if is_waiting_for_input:
				is_waiting_for_input = false
				$AnimationPlayer.play()  # Продолжаем анимацию
				return

func _on_texture_button_pressed() -> void:
	if is_waiting_for_input:
		is_waiting_for_input = false
		$AnimationPlayer.play_section("fox",current_position - 1.7, current_position)    # Продолжаем анимацию
		return

func _on_next_button_pressed() -> void:
	if is_waiting_for_input:
		is_waiting_for_input = false
		$AnimationPlayer.play()  # Продолжаем анимацию
		return


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	get_tree().change_scene_to_file("res://scenes/WorkbenchScene.tscn")
