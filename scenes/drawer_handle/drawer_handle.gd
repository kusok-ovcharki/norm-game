extends Node2D

const snap_duration := 0.1

var draggable := false
var drag_position_offset_y: float = 0
var initial_position: Vector2
var tween: Tween
var queue_deselect := false

var y_max := 220
var y_min := 0

func _ready() -> void:
	Dragging.object_selected.connect(select)

func select(object: Node2D):
	if object == self:
		draggable = true
		scale = Vector2(1.05, 1.05)
	else:
		draggable = false
		scale = Vector2(1, 1)

func _process(delta: float) -> void:
	if draggable:
		if Input.is_action_just_pressed("click"):
			initial_position = global_position
			drag_position_offset_y = global_position.y - get_global_mouse_position().y
			Dragging.drag_object_start(self)
		if Input.is_action_pressed("click"):
			var mouse_y = get_global_mouse_position().y
			var new_y = clamp(mouse_y + drag_position_offset_y, y_min, y_max)
			#global_position.y = new_y
			move_drawer(Vector2(global_position.x, new_y) - global_position)
		elif Input.is_action_just_released("click"):
			handle_reposition()

func move_drawer(vector: Vector2):
	var groups = get_groups()
	var i = groups.find_custom(func(name: StringName): return name.begins_with("drawer_"))
	if i == -1:
		return
	var drawer_group = groups[i]
	get_tree().call_group(drawer_group, "move", vector)

func move(vector: Vector2):
	global_position += vector

func handle_reposition():
	Dragging.drag_object_end(self)
	if queue_deselect == true:
		Dragging.deselect_object(self)
		queue_deselect = false

	#if is_inside_drop_zone():
		#var target_zone = find_target_zone()
		#if target_zone:
			#snap_to_zone(target_zone)
		#else:
			#reset_position()
	#elif !is_inside_dragging_zone || Dragging.fully_outside_of_dragging_zone():
		#reset_position()

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


func _on_area_2d_mouse_entered() -> void:
	queue_deselect = false
	if not Dragging.is_dragging:
		Dragging.select_object(self)


func _on_area_2d_mouse_exited() -> void:
	queue_deselect = true
	if not Dragging.is_dragging || Dragging.selected_object != self:
		queue_deselect = false
		Dragging.deselect_object(self)

func _notification(what):
	if what == NOTIFICATION_WM_MOUSE_EXIT && Dragging.selected_object == self:
		Dragging.deselect_object(self, true)
		handle_reposition()
