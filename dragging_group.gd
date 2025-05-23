extends Node2D

const top_z_index := 3000

var is_dragging := false;

var hovered_objects: Array[Node2D] = []

var selected_object: Node2D = null

var selected_object_z_index := -1

signal object_selected(object: Node2D)

func drag_object_start(object: Node2D):
	is_dragging = true
	object.z_index = top_z_index

func drag_object_end(object: Node2D):
	is_dragging = false
	object.z_index = selected_object_z_index

func select_object(object: Node2D):
	if is_dragging:
		return
	if (selected_object == null
		|| is_on_top(object, selected_object)):
		_set_selected_object(object)
	hovered_objects.append(object)

func deselect_object(object: Node2D):
	hovered_objects.erase(object)
	if selected_object == object:
		if hovered_objects.is_empty():
			_set_selected_object(null)
		else:
			var top_object = hovered_objects[0]
			for obj in hovered_objects:
				if is_on_top(obj, top_object):
					top_object = obj
			_set_selected_object(top_object)

func _set_selected_object(object: Node2D):
	selected_object = object
	selected_object_z_index = object.z_index if object != null else -1
	object_selected.emit(object)

func is_on_top(a: Node2D, b: Node2D):
	return (a.z_index > b.z_index
			|| (a.z_index == b.z_index && a.is_greater_than(b)))
