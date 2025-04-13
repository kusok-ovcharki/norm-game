extends Node2D
class_name DraggableObject

const snap_duration := 0.1

var draggable := false
var zone_refs: Array[Node2D]
var drag_position_offset: Vector2
var initial_position: Vector2
var is_inside_dragging_zone := true

var tween: Tween

@export var target_zone_id = "squareHole"

@export var areaGroups: Array[StringName] = []
@export var areaLayers: Array[int] = []

@export var draggingDisabled := false

@onready var raycastSE := $RayCast2DSE
@onready var raycastNW := $RayCast2DNW
@onready var raycastNE := $RayCast2DNE
@onready var raycastSW := $RayCast2DSW

@onready var area := $Area2D

func _ready() -> void:
	Dragging.object_selected.connect(select)
	for group in areaGroups:
		area.add_to_group(group)
	for layer in areaLayers:
		area.set_collision_layer_value(layer, true)

func select(object: Node2D):
	if draggingDisabled:
		return
	if object == self:
		draggable = true
		scale = Vector2(1.05, 1.05)
	else:
		draggable = false
		scale = Vector2(1, 1)

func _physics_process(delta: float) -> void:
	var collisions = [
		raycastSE.is_colliding(),
		raycastNW.is_colliding(),
		raycastSW.is_colliding(),
		raycastNE.is_colliding()
	]
	is_inside_dragging_zone = not true in collisions

func _process(delta: float) -> void:
	if draggable && !draggingDisabled:
		if Input.is_action_just_pressed("click"):
			initial_position = global_position
			drag_position_offset = global_position - get_global_mouse_position()
			Dragging.drag_object_start(self)
		if Input.is_action_pressed("click"):
			global_position = get_global_mouse_position() + drag_position_offset
		elif Input.is_action_just_released("click"):
			handle_reposition()


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

func _on_area_2d_mouse_entered() -> void:
	if draggingDisabled:
		return
	if not Dragging.is_dragging || Dragging.selected_object != self:
		Dragging.select_object(self)


func _on_area_2d_mouse_exited() -> void:
	if draggingDisabled:
		return
	if not Dragging.is_dragging || Dragging.selected_object != self:
		Dragging.deselect_object(self)


func _on_area_2d_body_entered(body: Node2D) -> void:
	if draggingDisabled:
		return
	if body.is_in_group("droppable"):
		zone_refs.append(body)


func _on_area_2d_body_exited(body: Node2D) -> void:
	if draggingDisabled:
		return
	if body.is_in_group("droppable"):
		zone_refs.erase(body)


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
