extends StaticBody2D

@export var id := "defaultScrew"

@onready var animated_sprite = $AnimatedSprite2D
@onready var interaction_area = $Area2D      # Зона взаимодействия
@onready var initial_position = position

var current_frame := 0  # Текущий кадр анимации
var is_screwdriver_in_zone := false

func _ready():
	animated_sprite.play("idle")

func get_zone_id() -> String:
	return id

func _input(event):
	if is_screwdriver_in_zone and event is InputEventMouseButton:
		# Обработка прокрутки вверх
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			animated_sprite.play("unscrewing")
			animated_sprite.pause()
			advance_animation()

func advance_animation():
	# Получаем количество кадров в текущей анимации
	var frame_count = animated_sprite.sprite_frames.get_frame_count("unscrewing")
	# Переключаем кадр
	current_frame = clampi(current_frame + 1, 0, frame_count - 1)
	animated_sprite.frame = current_frame
	# Обновляем позицию винтика (пример)
	position.y = initial_position.y - current_frame
	# Если достигнут последний кадр
	if current_frame == frame_count - 1:
		fully_unscrewed()

func fully_unscrewed():
	animated_sprite.play("removed")
	set_collision_layer_value(1, false)

func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("screwdriver"):
		is_screwdriver_in_zone = true

func _on_area_2d_area_exited(area: Area2D) -> void:
	if area.is_in_group("screwdriver"):
		is_screwdriver_in_zone = false
		if animated_sprite.animation == "unscrewing":
			animated_sprite.pause()
