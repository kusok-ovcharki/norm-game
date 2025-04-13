@tool
extends Area2D

@onready var sprite = $Sprite2D

var update_texture = false

@export var normal_texture: Texture2D:
	set(texture):
		print(texture)
		normal_texture = texture
		if normal_texture != null:
			update_texture = true
var normal_image : Image

@export var hover_texture: Texture2D
@export var brush_size := 20

var mask_texture: ImageTexture
var mask_image : Image

#var updating_enabled := false
var fully_cleaned := false

var painted_pixels := 0
var total_pixels := 0
@export var cleaning_threshold := 0.98
var completion_queued = false

var previous_brush_pos := Vector2.ZERO
var first_frame := true
var brush_step := 0.5  # Fraction of brush size between stamps (0.5 = 50%)

var paint_cooldown = 0.0
var paint_rate = 0.016  # ~60 FPS

var brush: Node2D

var alpha_threshold: float = 0.5

@onready var collision = $CollisionPolygon2D

signal cleaned()
	
	
	
func _on_texture_changed():
	create_texture_and_collision()
	
func create_texture_and_collision():
	# Initialize textures
	sprite.texture = normal_texture
	
	var outline_polygon = get_centered_outline()
	collision.polygon = outline_polygon
	
	normal_image = normal_texture.get_image()
	mask_image = Image.create(normal_texture.get_width(), normal_texture.get_height(), false, Image.FORMAT_RGBA8)
	mask_image.fill(Color(0, 0, 0, 0))  # Start fully transparent
	mask_texture = ImageTexture.create_from_image(mask_image)
	
	# Assign shader parameters
	sprite.material.set_shader_parameter("normal_tex", normal_texture)
	sprite.material.set_shader_parameter("hover_tex", hover_texture)
	sprite.material.set_shader_parameter("mask_tex", mask_texture)
	
	# Initialize total pixels
	var tex_size = normal_texture.get_size()
	#total_pixels = tex_size.x * tex_size.y
	
	var count = 0
	for y in tex_size.y:
		for x in tex_size.x:
			if normal_image.get_pixel(x, y).a > alpha_threshold:
				count += 1
	total_pixels = count
	
	
	# Count initially painted pixels
	painted_pixels = count_painted_pixels()
	
func get_centered_outline():
	var outline = get_texture_outline()  # From previous function
	var tex_size = sprite.texture.get_size()
	
	# Convert from texture space to centered sprite space
	for i in outline.size():
		outline[i] -= tex_size / 2.0
	
	return outline
	
func get_texture_outline():
	var image = sprite.texture.get_image()
	
	# Create bitmask of opaque pixels
	var bitmap := BitMap.new()
	bitmap.create_from_image_alpha(image, alpha_threshold)
	
	# Get all polygons (including holes)
	var all_polys := bitmap.opaque_to_polygons(Rect2(Vector2.ZERO, image.get_size()), 1.0)
	
	# Find the largest polygon (main outline)
	var largest_area := 0.0
	var main_polygon: PackedVector2Array
	
	for poly in all_polys:
		var area = calculate_area(poly)
		if area > largest_area:
			largest_area = area
			main_polygon = poly
	
	return main_polygon
	
func calculate_area(mesh_vertices: PackedVector2Array) -> float:
	var result := 0.0
	var num_vertices := mesh_vertices.size()

	for q in range(num_vertices):
		var p = (q - 1 + num_vertices) % num_vertices
		result += mesh_vertices[q].cross(mesh_vertices[p])
	
	return abs(result) * 0.5

func _process(delta):
	if update_texture:
		update_texture = false
		_on_texture_changed()
		
	if brush == null || fully_cleaned:
		return
	update_mask()
	check_completion()

func update_mask():
	# Get global position and convert to local node space
	var global_brush_pos = brush.global_position
	var current_brush_pos = to_local(global_brush_pos)
	
	var img = mask_texture.get_image()
	var tex_size = normal_texture.get_size()
	
	var current_tex_pos = Vector2(
		clamp(current_brush_pos.x + tex_size.x/2, 0, tex_size.x),
		clamp(current_brush_pos.y + tex_size.y/2, 0, tex_size.y)
	)
	
	if first_frame:
		previous_brush_pos = current_tex_pos
		first_frame = false
		
	# Calculate distance between current and previous positions
	var distance = previous_brush_pos.distance_to(current_tex_pos)
	var steps = ceil(distance / (brush_size * brush_step))
	
	# Interpolate between previous and current positions
	for i in range(steps + 1):
		var t = float(i) / steps
		var interp_pos = previous_brush_pos.lerp(current_tex_pos, t)
		paint_at_position(interp_pos)
	
	previous_brush_pos = current_tex_pos
	
func paint_at_position(pos: Vector2):
	var tex_size = normal_texture.get_size()
	var pixels_painted = 0
	
	# Paint with soft brush
	for dx in range(-brush_size, brush_size):
		for dy in range(-brush_size, brush_size):
			var dist = Vector2(dx, dy).length()
			if dist > brush_size:
				continue
				
			var px = pos.x + dx
			var py = pos.y + dy
			if px < 0 || px >= tex_size.x || py < 0 || py >= tex_size.y:
				continue
				
			# Calculate paint strength
			var current_alpha = mask_image.get_pixel(px, py).r
			var new_alpha = clamp(1.0 - dist/brush_size, 0, 1)
			
			if new_alpha > current_alpha:
				mask_image.set_pixel(px, py, Color(1, 1, 1, new_alpha))
				if current_alpha < 0.1 && normal_image.get_pixel(px, py).a > alpha_threshold:  # Only count newly painted pixels
					pixels_painted += 1
	
	painted_pixels += pixels_painted
	mask_texture.set_image(mask_image)
	
func check_completion():
	if completion_queued: return
	
	var progress = float(painted_pixels) / total_pixels
	if progress >= cleaning_threshold:
		completion_queued = true
		finish_cleaning()

func finish_cleaning():
	# Fill any remaining pixels
	for y in mask_image.get_height():
		for x in mask_image.get_width():
			if mask_image.get_pixel(x, y).r < 0.1:
				mask_image.set_pixel(x, y, Color.WHITE)
	mask_texture.set_image(mask_image)
	fully_cleaned = true
	print("emit cleaned")
	cleaned.emit()
	
func count_painted_pixels() -> int:
	var count = 0
	for y in mask_image.get_height():
		for x in mask_image.get_width():
			if mask_image.get_pixel(x, y).r > 0.1:
				count += 1
	return count

func _on_mouse_entered() -> void:
	#updating_enabled = true
	pass


func _on_mouse_exited() -> void:
	#updating_enabled = false
	pass


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("brush"):
		brush = body


func _on_body_exited(body: Node2D) -> void:
	if body == brush:
		brush = null


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("brush"):
		brush = area


func _on_area_exited(area: Area2D) -> void:
	if area == brush:
		brush = null
