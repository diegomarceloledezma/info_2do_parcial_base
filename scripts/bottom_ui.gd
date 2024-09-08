extends TextureRect

@onready var label = $MarginContainer/HBoxContainer/Label

var current_level = 1

func _ready():
	update_level_text()

func increment_level():
	current_level += 1
	update_level_text()

func game_over():
	print("GAME OVER")
	label.text = "PERDISTE :("

func set_text(new_text: String):
	label.text = new_text

func update_level_text():
	if current_level == 1:
		label.text = "Nivel 1"
	elif current_level == 2:
		label.text = "Nivel 2"
	else:
		label.text = "You Win!!"
