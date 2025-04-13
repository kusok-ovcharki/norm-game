extends Node

var volume: float = 1

signal volume_changed(volume: float)

func change_volume(value: float):
	volume = value
	volume_changed.emit(volume)
