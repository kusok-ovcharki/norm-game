extends AudioStreamPlayer2D

func _ready() -> void:
	change_volume(Settings.volume)
	Settings.connect("volume_changed", change_volume)
	
func change_volume(value: float):
	volume_db = linear_to_db(value)
	
