extends Control

var dialogues = [
	"Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book. It has survived not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum.",
	"Привет! Добро пожаловать в нашу визуальную новеллу.",
	"Это пример диалога.",
	"Надеюсь, вам понравится!"
]

var current_dialogue_index = 0

func _ready():
	$TextureRect/RichTextLabel.text = dialogues[current_dialogue_index]

func _on_margin_container_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
			if current_dialogue_index < dialogues.size()-1:
				current_dialogue_index += 1
				print(current_dialogue_index)
				$TextureRect/RichTextLabel.text = dialogues[current_dialogue_index]
				if current_dialogue_index == dialogues.size()-1:
					$NextButton.disabled = true
				elif current_dialogue_index == 1:
						$PrevButton.disabled = false

func _on_texture_button_pressed() -> void:
	if current_dialogue_index > 0:
		current_dialogue_index -= 1
		$TextureRect/RichTextLabel.text = dialogues[current_dialogue_index]
		print(current_dialogue_index)
		if current_dialogue_index == 0:
			$PrevButton.disabled = true
		if $NextButton.disabled == true:
				$NextButton.disabled = false 

func _on_next_button_pressed() -> void:
	if current_dialogue_index < dialogues.size()-1:
		current_dialogue_index += 1
		$TextureRect/RichTextLabel.text = dialogues[current_dialogue_index]
		print(current_dialogue_index)
		if current_dialogue_index == dialogues.size()-1:
			$NextButton.disabled = true
		if $PrevButton.disabled == true:
				$PrevButton.disabled = false 
