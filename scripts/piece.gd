extends Node2D

@export var color: String
@export var type: String = ""  # Puede ser "normal", "Horizontal", "Vertical", "Adjacent"

var matched = false
var grid = null  # Variable para almacenar la referencia de grid

func move(target):
	var move_tween = create_tween()
	move_tween.set_trans(Tween.TRANS_ELASTIC)
	move_tween.set_ease(Tween.EASE_OUT)
	move_tween.tween_property(self, "position", target, 0.4)

func dim():
	$Sprite2D.modulate = Color(1, 1, 1, 0.5)

func normal():
	$Sprite2D.modulate = Color(1, 1, 1, 1)

func set_piece_type(new_type: String):
	type = new_type
	grid.update_piece_sprite(self)
