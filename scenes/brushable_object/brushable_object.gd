extends DraggableObject

@onready var brushableSprite = $brushableSprite

@export var target_zone_if_cleaned = ""

@export var normal_texture: Texture2D
@export var hover_texture: Texture2D
@export var brush_size := 20

func _ready() -> void:
	super._ready()
	brushableSprite.connect("cleaned", on_cleaned)
	brushableSprite.normal_texture = normal_texture
	brushableSprite.hover_texture = hover_texture
	brushableSprite.brush_size = brush_size
	
func on_cleaned():
	target_zone_id = target_zone_if_cleaned
