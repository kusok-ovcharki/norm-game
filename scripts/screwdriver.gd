extends Node2D

const snap_duration := 0.1

var draggable := false
var zone_refs: Array[Node2D]
var drag_position_offset: Vector2
var initial_position: Vector2
var is_inside_dragging_zone := true
var initial_rotation: float
var current_frame := 0  # Текущий кадр анимации
var tween: Tween

@export var target_zone_id = "defaultScrew"
@export var target_rotation_degrees: float = 180.0  # Угол, на который повернётся объект
@export var rotation_duration: float = 0.5        # Длительность анимации в секундах

@onready var raycastDown := $RayCast2DDown
@onready var raycastUp := $RayCast2DUp
@onready var raycastLeft := $RayCast2DLeft
@onready var raycastRight := $RayCast2DRight
@onready var animated_sprite = $AnimatedSprite2D
@onready var area := $Area2D

func _ready() -> void:
	Dragging.object_selected.connect(select)
	initial_rotation = rotation_degrees
	animated_sprite.play("idle")

func select(object: Node2D):
	if object == self:
		draggable = true
		scale = Vector2(1.05, 1.05)
	else:
		draggable = false
		scale = Vector2(1, 1)

func _physics_process(delta: float) -> void:
	var collisions = [
		raycastDown.is_colliding(),
		raycastUp.is_colliding(),
		raycastRight.is_colliding(),
		raycastLeft.is_colliding()
	]
	is_inside_dragging_zone = not true in collisions


func _process(delta: float) -> void:
	if draggable:
		if Input.is_action_just_pressed("click"):
			initial_position = global_position
			drag_position_offset = global_position - get_global_mouse_position()
			Dragging.drag_object_start(self)
		if Input.is_action_pressed("click"):
			global_position = get_global_mouse_position() + drag_position_offset
		elif Input.is_action_just_released("click"):
			handle_reposition()

############# Откручивание ##########

func _input(event):
	if event is InputEventMouseButton:
		# Обработка прокрутки вверх
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			advance_animation()

func advance_animation():
	# Получаем количество кадров в текущей анимации
	var frame_count = animated_sprite.sprite_frames.get_frame_count("unscrewing")
	# Переключаем кадр
	current_frame = clampi(current_frame + 1, 0, frame_count - 1)
	animated_sprite.frame = current_frame
	# Если достигнут последний кадр
	if current_frame == frame_count - 1:
		current_frame = -1

#######################################

func handle_reposition():
	Dragging.drag_object_end(self)
	if is_inside_drop_zone():
		var target_zone = find_target_zone()
		if target_zone:
			snap_to_zone(target_zone)
		else:
			reset_position()
	elif !is_inside_dragging_zone || Dragging.fully_outside_of_dragging_zone():
		reset_position()

func reset_position():
	if tween:
		tween.kill()
	tween = get_tree().create_tween()
	tween.tween_property(
		self,
		"global_position",
		initial_position,
		snap_duration
	).set_ease(Tween.EASE_OUT)

func snap_to_zone(zone: Node2D):
	if tween:
		tween.kill()
	tween = get_tree().create_tween()
	tween.tween_property(
		self,
		"position",
		zone.position,
		snap_duration
	).set_ease(Tween.EASE_OUT)

func is_inside_drop_zone() -> bool:
	return zone_refs.size()

func is_target_zone(zone: Node2D) -> bool:
	return zone.has_method("get_zone_id") && zone.get_zone_id() == target_zone_id

func find_target_zone() -> Node2D:
	var i = zone_refs.find_custom(is_target_zone.bind())
	if i == -1:
		return null
	return zone_refs[i]

func move(vector: Vector2):
	global_position += vector

func _on_area_2d_handle_mouse_entered() -> void:
	if not Dragging.is_dragging || Dragging.selected_object != self:
		Dragging.select_object(self)

func _on_area_2d_handle_mouse_exited() -> void:
	if not Dragging.is_dragging || Dragging.selected_object != self:
		Dragging.deselect_object(self)

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("droppable"):
		zone_refs.append(body)
		rotate_to_target(target_rotation_degrees)
		animated_sprite.play("unscrewing")
		animated_sprite.pause()
		animated_sprite.frame = 0


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.is_in_group("droppable"):
		zone_refs.erase(body)
		rotate_to_target(initial_rotation)
		if rotation_degrees == target_rotation_degrees:
			animated_sprite.play("idle")
			


func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("drawer_left"):
		add_to_group("drawer_left")
	if area.is_in_group("drawer_center"):
		add_to_group("drawer_center")
	if area.is_in_group("drawer_right"):
		add_to_group("drawer_right")


func _on_area_2d_area_exited(area: Area2D) -> void:
	if area.is_in_group("drawer_left"):
		remove_from_group("drawer_left")
	if area.is_in_group("drawer_center"):
		remove_from_group("drawer_center")
	if area.is_in_group("drawer_right"):
		remove_from_group("drawer_right")

func _notification(what):
	if what == NOTIFICATION_WM_MOUSE_EXIT && Dragging.selected_object == self:
		Dragging.deselect_object(self, true)
		handle_reposition()

func rotate_to_target(rotation_degrees: float):
	if tween:
		tween.kill()  # Останавливаем предыдущий твин, если был
	tween = create_tween()
	tween.tween_property(
		self, 
		"rotation_degrees", 
		rotation_degrees, 
		rotation_duration
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
