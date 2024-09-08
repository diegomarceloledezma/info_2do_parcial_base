extends Node2D

# state machine
enum {WAIT, MOVE}
var state
var level = 1

# grid
@export var width: int
@export var height: int
@export var x_start: int
@export var y_start: int
@export var offset: int
@export var y_offset: int

# piece array
var possible_pieces = [
	preload("res://scenes/blue_piece.tscn"), #0 Blue
	preload("res://scenes/green_piece.tscn"), #1 Green
	preload("res://scenes/light_green_piece.tscn"), #2 Light Green
	preload("res://scenes/pink_piece.tscn"), #3 Pink
	preload("res://scenes/yellow_piece.tscn"), #4 Yellow
	preload("res://scenes/orange_piece.tscn") #5 Orange
]

var horizontal_pieces = [
	preload("res://scenes/blue_row.tscn"), #0 Blue
	preload("res://scenes/green_row.tscn"), #1 Green
	preload("res://scenes/light_green_row.tscn"), #2 Light Green
	preload("res://scenes/pink_row.tscn"), #3 Pink
	preload("res://scenes/yellow_row.tscn"), #4 Yellow
	preload("res://scenes/orange_row.tscn"), #5 Orange
]

var vertical_pieces = [
	preload("res://scenes/blue_column.tscn"), #0 Blue
	preload("res://scenes/green_column.tscn"), #1 Green
	preload("res://scenes/light_green_column.tscn"), #2 Light Green
	preload("res://scenes/pink_column.tscn"), #3 Pink
	preload("res://scenes/yellow_column.tscn"), #4 Yellow
	preload("res://scenes/orange_column.tscn") #5 Orange
]

var all_directions_pieces = [
	preload("res://scenes/blue_adjacent.tscn"), #0 Blue
	preload("res://scenes/green_adjacent.tscn"), #1 Green
	preload("res://scenes/light_green_adjacent.tscn"), #2 Light Green
	preload("res://scenes/pink_adjacent.tscn"), #3 Pink
	preload("res://scenes/yellow_adjacent.tscn"), #4 Yellow
	preload("res://scenes/orange_adjacent.tscn") #5 Orange
]

var color_index = {
	"blue": 0,
	"green": 1,
	"light_green": 2,
	"pink": 3,
	"yellow": 4,
	"orange": 5
}


# swap back
var piece_one = null
var piece_two = null
var last_place = Vector2.ZERO
var last_direction = Vector2.ZERO
var move_checked = false

# touch variables
var first_touch = Vector2.ZERO
var final_touch = Vector2.ZERO
var is_controlling = false
var matched_four = []
var matched_five = []
# scoring variables and signals
var score = 0
var score_goal = 0
var match_count = 0
# counter variables and signals
var is_move = false
var time_timer
var all_pieces = []
var moves
var time

# Called when the node enters the scene tree for the first time.
func _ready():
	state = MOVE
	randomize()
	moves = 20
	score_goal = 1000
	get_parent().get_node("top_ui").initCurrentCount(moves)
	get_parent().get_node("top_ui").initGoal(score_goal)
	all_pieces = make_2d_array()
	spawn_pieces()
	
func start_new_level():
	if level == 2:
		clear_previous_pieces()
		score = 0
		time = 100
		score_goal = 1200  # Cambia el objetivo de puntaje
		# Actualiza el contador de tiempo y puntaje
		get_parent().get_node("top_ui").initCurrentCount(time)
		get_parent().get_node("top_ui").initCurrentScore(score)
		get_parent().get_node("top_ui").updateGoal(score_goal)  # Actualiza el objetivo de puntaje

		# Cambiar el texto en bottom_ui para reflejar el nuevo nivel
		get_parent().get_node("bottom_ui").increment_level()
		
		all_pieces = make_2d_array()
		spawn_pieces()
		state = WAIT
		get_parent().get_node("next_level").start()
		
		print("Level 2 started")
	else:
		print("No hay más niveles")


func clear_previous_pieces():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				all_pieces[i][j].queue_free()
				all_pieces[i][j] = null 

func make_2d_array():
	var array = []
	for i in width:
		array.append([])
		for j in height:
			array[i].append(null)
	return array
	
func grid_to_pixel(column, row):
	var new_x = x_start + offset * column
	var new_y = y_start - offset * row
	return Vector2(new_x, new_y)
	
func pixel_to_grid(pixel_x, pixel_y):
	var new_x = round((pixel_x - x_start) / offset)
	var new_y = round((pixel_y - y_start) / -offset)
	return Vector2(new_x, new_y)
	
func in_grid(column, row):
	return column >= 0 and column < width and row >= 0 and row < height
	
func spawn_pieces():
	for i in width:
		for j in height:
			# random number
			var rand = randi_range(0, possible_pieces.size() - 1)
			# instance 
			var piece = possible_pieces[rand].instantiate()
			# repeat until no matches
			var max_loops = 100
			var loops = 0
			while (match_at(i, j, piece.color) and loops < max_loops):
				rand = randi_range(0, possible_pieces.size() - 1)
				loops += 1
				piece = possible_pieces[rand].instantiate()
			add_child(piece)
			piece.position = grid_to_pixel(i, j)
			# fill array with pieces
			all_pieces[i][j] = piece

func match_at(i, j, color):
	# check left
	if i > 1:
		if all_pieces[i - 1][j] != null and all_pieces[i - 2][j] != null:
			if all_pieces[i - 1][j].color == color and all_pieces[i - 2][j].color == color:
				return true
	# check down
	if j> 1:
		if all_pieces[i][j - 1] != null and all_pieces[i][j - 2] != null:
			if all_pieces[i][j - 1].color == color and all_pieces[i][j - 2].color == color:
				return true

func touch_input():
	var mouse_pos = get_global_mouse_position()
	var grid_pos = pixel_to_grid(mouse_pos.x, mouse_pos.y)
	if Input.is_action_just_pressed("ui_touch") and in_grid(grid_pos.x, grid_pos.y):
		first_touch = grid_pos
		is_controlling = true
		
	# release button
	if Input.is_action_just_released("ui_touch") and in_grid(grid_pos.x, grid_pos.y) and is_controlling:
		is_controlling = false
		final_touch = grid_pos
		touch_difference(first_touch, final_touch)

func swap_pieces(column, row, direction: Vector2):
	is_move = true
	var first_piece = all_pieces[column][row]
	var other_piece = all_pieces[column + direction.x][row + direction.y]
	if first_piece == null or other_piece == null:
		return
	# swap
	state = WAIT
	store_info(first_piece, other_piece, Vector2(column, row), direction)
	all_pieces[column][row] = other_piece
	all_pieces[column + direction.x][row + direction.y] = first_piece
	#first_piece.position = grid_to_pixel(column + direction.x, row + direction.y)
	#other_piece.position = grid_to_pixel(column, row)
	first_piece.move(grid_to_pixel(column + direction.x, row + direction.y))
	other_piece.move(grid_to_pixel(column, row))
	if not move_checked:
		find_matches()
	

func store_info(first_piece, other_piece, place, direction):
	piece_one = first_piece
	piece_two = other_piece
	last_place = place
	last_direction = direction

func swap_back():
	is_move = false
	if piece_one != null and piece_two != null:
		swap_pieces(last_place.x, last_place.y, last_direction)
	state = MOVE
	move_checked = false

func touch_difference(grid_1, grid_2):
	var difference = grid_2 - grid_1
	# should move x or y?
	if abs(difference.x) > abs(difference.y):
		if difference.x > 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(1, 0))
		elif difference.x < 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(-1, 0))
	if abs(difference.y) > abs(difference.x):
		if difference.y > 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(0, 1))
		elif difference.y < 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(0, -1))

func _process(delta):
	if state == MOVE:
		if is_move and match_count>0:
			if level == 1:
				get_parent().get_node("top_ui").decrease_count()
				moves-=1
				get_parent().get_node("top_ui").increment_counter(10 * match_count)
				score+=10*match_count
				if(moves <= 0 and score < score_goal):
					game_over()
				if(score >= score_goal):
					level+= 1
					start_new_level()
				is_move = false
			else:
				get_parent().get_node("top_ui").increment_counter(10*match_count)
				score+=10*match_count
				if(time <= 0 and score < score_goal):
					game_over()
				if(score >= score_goal):
					get_parent().get_node("second_timer").stop() 
					if level == 2:
						# Si es el nivel 2 y se alcanzó el objetivo
						get_parent().get_node("bottom_ui").set_text("¡¡GANASTE!!")
						state = WAIT  # Pausa el juego
					else:
						# Si es cualquier otro nivel, pasa al siguiente
						level += 1
						state = WAIT
						start_new_level()
				is_move = false
		match_count = 0
		touch_input()
		
func update_piece_sprite(is_vertical: bool = false):
	var color_idx = color_index.get(matched_four, -1)
	var scene = null
	
	if matched_four.type == "Horizontal":
		scene = horizontal_pieces[color_idx]
	elif matched_four.type == "Vertical":
		scene = vertical_pieces[color_idx]
	elif matched_four.type == "Adjacent":
		scene = all_directions_pieces[color_idx]
	else:
		scene = possible_pieces[color_idx]

	if scene:
		var new_sprite_instance = scene.instantiate()

		if matched_four.has_node("Sprite2D"):
			matched_four.remove_child(matched_four.get_node("Sprite2D"))
			matched_four.get_node("Sprite2D").queue_free()
		
		matched_four.add_child(new_sprite_instance)
		new_sprite_instance.name = "Sprite2D"
		
func matched_all1(i , j):
	all_pieces[i][j+ 1].matched = true
	all_pieces[i][j+ 1].dim()
	all_pieces[i + 1][j].matched = true
	all_pieces[i + 1][j].dim()
	all_pieces[i + 2][j].matched = true
	all_pieces[i + 2][j].dim()
	all_pieces[i ][j - 1].matched = true
	all_pieces[i ][j - 1].dim()
	all_pieces[i][j].matched = true
	all_pieces[i][j].dim()

func matched_all2(i,j):
	all_pieces[i][j- 1].matched = true
	all_pieces[i][j- 1].dim()
	all_pieces[i + 1][j].matched = true
	all_pieces[i + 1][j].dim()
	all_pieces[i + 2][j].matched = true
	all_pieces[i + 2][j].dim()
	all_pieces[i ][j - 2].matched = true
	all_pieces[i ][j - 2].dim()
	all_pieces[i][j].matched = true
	all_pieces[i][j].dim()

func matched_all3(i,j):
	all_pieces[i][j+1].matched = true
	all_pieces[i][j+1].dim()
	all_pieces[i + 1][j].matched = true
	all_pieces[i + 1][j].dim()
	all_pieces[i + 2][j].matched = true
	all_pieces[i + 2][j].dim()
	all_pieces[i][j +2].matched = true
	all_pieces[i][j +2].dim()
	all_pieces[i][j].matched = true
	all_pieces[i][j].dim()

func matched_all4(i,j):
	all_pieces[i][j].matched = true
	all_pieces[i][j].dim()
	all_pieces[i][j - 1].matched = true
	all_pieces[i][j - 1].dim()
	all_pieces[i + 1][j].matched = true
	all_pieces[i + 1][j].dim()
	all_pieces[i -1][j].matched = true
	all_pieces[i -1][j].dim()
	all_pieces[i ][j - 2].matched = true
	all_pieces[i ][j - 2].dim()

func matched_all5(i,j):
	all_pieces[i - 1][j].matched = true
	all_pieces[i - 1][j].dim()
	all_pieces[i + 1][j].matched = true
	all_pieces[i + 1][j].dim()
	all_pieces[i][j + 1].matched = true
	all_pieces[i][j + 1].dim()
	all_pieces[i][j - 1].matched = true
	all_pieces[i][j - 1].dim()
	all_pieces[i][j].matched = true
	all_pieces[i][j].dim()

func matched_all6(i,j):
	all_pieces[i - 1][j].matched = true
	all_pieces[i - 1][j].dim()
	all_pieces[i - 2][j].matched = true
	all_pieces[i - 2][j].dim()
	all_pieces[i][j - 1].matched = true
	all_pieces[i][j - 1].dim()
	all_pieces[i][j - 2].matched = true
	all_pieces[i][j - 2].dim()
	all_pieces[i][j].matched = true
	all_pieces[i][j].dim()

func matched_all7(i,j):
	all_pieces[i - 1][j].matched = true
	all_pieces[i - 1][j].dim()
	all_pieces[i - 2][j].matched = true
	all_pieces[i - 2][j].dim()
	all_pieces[i][j + 1].matched = true
	all_pieces[i][j + 1].dim()
	all_pieces[i][j + 2].matched = true
	all_pieces[i][j + 2].dim()
	all_pieces[i][j].matched = true
	all_pieces[i][j].dim()

func last_all1(i , j):
	if last_place.x == i and last_place.y==j:
		matched_five.append([i, j , all_pieces[i][j],true])
	elif last_place.x == i+1 and last_place.y==j:
		matched_five.append([i+1, j , all_pieces[i][j],true])
	elif last_place.x == i+2 and last_place.y==j:
		matched_five.append([i+2, j , all_pieces[i][j],true])
	elif last_place.x == i and last_place.y==j-1:
		matched_five.append([i, j-1 , all_pieces[i][j],true])
	elif last_place.x == i and last_place.y==j+1:
		matched_five.append([i, j+1 , all_pieces[i][j],true])
	elif last_place.x + last_direction.x == i and last_place.y + last_direction.y==j:
		matched_five.append([i, j , all_pieces[i][j],true])
	elif last_place.x + last_direction.x == i+1 and last_place.y+ last_direction.y==j:
		matched_five.append([i+1, j , all_pieces[i][j],true])
	elif last_place.x + last_direction.x == i+2 and last_place.y+ last_direction.y==j:
		matched_five.append([i+2, j , all_pieces[i][j],true])
	elif last_place.x + last_direction.x == i and last_place.y+ last_direction.y==j-1:
		matched_five.append([i, j-1 , all_pieces[i][j],true])
	elif last_place.x + last_direction.x == i and last_place.y+ last_direction.y==j+1:
		matched_five.append([i, j+1 , all_pieces[i][j],true])
	else:
		matched_five.append([i, j , all_pieces[i][j],true])

func last_all6(i,j):
	if last_place.x == i and last_place.y == j:
		matched_five.append([i, j, all_pieces[i][j], true])
	elif last_place.x == i - 1 and last_place.y == j:
		matched_five.append([i - 1, j, all_pieces[i][j], true])
	elif last_place.x == i - 2 and last_place.y == j:
		matched_five.append([i - 2, j, all_pieces[i][j], true])
	elif last_place.x == i and last_place.y == j - 1:
		matched_five.append([i, j - 1, all_pieces[i][j], true])
	elif last_place.x == i and last_place.y == j - 2:
		matched_five.append([i, j - 2, all_pieces[i][j], true])
	elif last_place.x + last_direction.x == i and last_place.y + last_direction.y == j:
		matched_five.append([i, j, all_pieces[i][j], true])
	elif last_place.x + last_direction.x == i - 1 and last_place.y + last_direction.y == j:
		matched_five.append([i - 1, j, all_pieces[i][j], true])
	elif last_place.x + last_direction.x == i - 2 and last_place.y + last_direction.y == j:
		matched_five.append([i - 2, j, all_pieces[i][j], true])
	elif last_place.x + last_direction.x == i and last_place.y + last_direction.y == j - 1:
		matched_five.append([i, j - 1, all_pieces[i][j], true])
	elif last_place.x + last_direction.x == i and last_place.y + last_direction.y == j - 2:
		matched_five.append([i, j - 2, all_pieces[i][j], true])
	else:
		matched_five.append([i, j, all_pieces[i][j], true])

func last_all2(i,j):
	if last_place.x == i and last_place.y==j:
		matched_five.append([i, j , all_pieces[i][j],true])
	elif last_place.x == i+1 and last_place.y==j:
		matched_five.append([i+1, j , all_pieces[i][j],true])
	elif last_place.x == i+2 and last_place.y==j:
		matched_five.append([i+2, j , all_pieces[i][j],true])
	elif last_place.x == i and last_place.y==j-2:
		matched_five.append([i, j-2 , all_pieces[i][j],true])
	elif last_place.x == i and last_place.y==j-1:
		matched_five.append([i, j-1 , all_pieces[i][j],true])
	elif last_place.x + last_direction.x == i and last_place.y + last_direction.y==j:
		matched_five.append([i, j , all_pieces[i][j],true])
	elif last_place.x + last_direction.x == i+1 and last_place.y+ last_direction.y==j:
		matched_five.append([i+1, j , all_pieces[i][j],true])
	elif last_place.x + last_direction.x == i+2 and last_place.y+ last_direction.y==j:
		matched_five.append([i+2, j , all_pieces[i][j],true])
	elif last_place.x + last_direction.x == i and last_place.y+ last_direction.y==j-2:
		matched_five.append([i, j-2 , all_pieces[i][j],true])
	elif last_place.x + last_direction.x == i and last_place.y+ last_direction.y==j-1:
		matched_five.append([i, j-1 , all_pieces[i][j],true])
	else:
		matched_five.append([i, j , all_pieces[i][j],true])

func last_all3(i,j):
	if last_place.x == i and last_place.y==j:
		matched_five.append([i, j , all_pieces[i][j],true])
	elif last_place.x == i+1 and last_place.y==j:
		matched_five.append([i+1, j , all_pieces[i][j],true])
	elif last_place.x == i+2 and last_place.y==j:
		matched_five.append([i+2, j, all_pieces[i][j],true])
	elif last_place.x == i and last_place.y==j+2:
		matched_five.append([i, j+2 , all_pieces[i][j],true])
	elif last_place.x == i and last_place.y==j+1:
		matched_five.append([i, j+1 , all_pieces[i][j],true])
	elif last_place.x + last_direction.x == i and last_place.y + last_direction.y==j:
		matched_five.append([i, j , all_pieces[i][j],true])
	elif last_place.x + last_direction.x == i+1 and last_place.y+ last_direction.y==j:
		matched_five.append([i+1, j , all_pieces[i][j],true])
	elif last_place.x + last_direction.x == i+2 and last_place.y+ last_direction.y==j:
		matched_five.append([i+2, j , all_pieces[i][j],true])
	elif last_place.x + last_direction.x == i and last_place.y+ last_direction.y==j+2:
		matched_five.append([i, j+2 , all_pieces[i][j],true])
	elif last_place.x + last_direction.x == i and last_place.y+ last_direction.y==j+1:
		matched_five.append([i, j+1 , all_pieces[i][j],true])
	else:
		matched_five.append([i, j , all_pieces[i][j],true])

func last_all4(i,j):
	if last_place.x == i and last_place.y == j:
		matched_five.append([i, j, all_pieces[i][j], true])
	elif last_place.x == i + 1 and last_place.y == j:
		matched_five.append([i + 1, j, all_pieces[i][j], true])
	elif last_place.x == i  and last_place.y == j - 1:
		matched_five.append([i, j - 1, all_pieces[i][j], true])
	elif last_place.x == i and last_place.y == j - 2:
		matched_five.append([i, j - 2, all_pieces[i][j], true])
	elif last_place.x == i-1  and last_place.y == j:
		matched_five.append([i - 1, j, all_pieces[i][j], true])
		
	elif last_place.x + last_direction.x == i and last_place.y + last_direction.y == j:
		matched_five.append([i, j, all_pieces[i][j], true])
	elif last_place.x + last_direction.x == i + 1 and last_place.y + last_direction.y == j:
		matched_five.append([i + 1, j, all_pieces[i][j], true])
	elif last_place.x + last_direction.x == i  and last_place.y + last_direction.y == j - 1:
		matched_five.append([i , j - 1, all_pieces[i][j], true])
	elif last_place.x + last_direction.x == i  and last_place.y + last_direction.y == j - 2:
		matched_five.append([i , j - 2, all_pieces[i][j], true])
	elif last_place.x + last_direction.x == i-1 and last_place.y + last_direction.y == j :
		matched_five.append([i-1, j , all_pieces[i][j], true])
	else:
		matched_five.append([i, j, all_pieces[i][j], true])

func last_all5(i,j):
	if last_place.x == i and last_place.y == j:
		matched_five.append([i, j, all_pieces[i][j], true])
	elif last_place.x == i - 1 and last_place.y == j:
		matched_five.append([i - 1, j, all_pieces[i][j], true])
	elif last_place.x == i + 1 and last_place.y == j:
		matched_five.append([i + 1, j, all_pieces[i][j], true])
	elif last_place.x == i and last_place.y == j + 1:
		matched_five.append([i, j + 1, all_pieces[i][j], true])
	elif last_place.x == i and last_place.y == j - 1:
		matched_five.append([i, j - 1, all_pieces[i][j], true])
	elif last_place.x + last_direction.x == i and last_place.y + last_direction.y == j:
		matched_five.append([i, j, all_pieces[i][j], true])
	elif last_place.x + last_direction.x == i - 1 and last_place.y + last_direction.y == j:
		matched_five.append([i - 1, j, all_pieces[i][j], true])
	elif last_place.x + last_direction.x == i + 1 and last_place.y + last_direction.y == j:
		matched_five.append([i + 1, j, all_pieces[i][j], true])
	elif last_place.x + last_direction.x == i and last_place.y + last_direction.y == j + 1:
		matched_five.append([i, j + 1, all_pieces[i][j], true])
	elif last_place.x + last_direction.x == i and last_place.y + last_direction.y == j - 1:
		matched_five.append([i, j - 1, all_pieces[i][j], true])
	else:
		matched_five.append([i, j, all_pieces[i][j], true])

func last_all7(i,j):
	if last_place.x == i and last_place.y == j:
		matched_five.append([i, j, all_pieces[i][j], true])
	elif last_place.x == i - 1 and last_place.y == j:
		matched_five.append([i - 1, j, all_pieces[i][j], true])
	elif last_place.x == i - 2 and last_place.y == j:
		matched_five.append([i - 2, j, all_pieces[i][j], true])
	elif last_place.x == i and last_place.y == j + 1:
		matched_five.append([i, j + 1, all_pieces[i][j], true])
	elif last_place.x == i and last_place.y == j + 2:
		matched_five.append([i, j + 2, all_pieces[i][j], true])
	elif last_place.x + last_direction.x == i and last_place.y + last_direction.y == j:
		matched_five.append([i, j, all_pieces[i][j], true])
	elif last_place.x + last_direction.x == i - 1 and last_place.y + last_direction.y == j:
		matched_five.append([i - 1, j, all_pieces[i][j], true])
	elif last_place.x + last_direction.x == i - 2 and last_place.y + last_direction.y == j:
		matched_five.append([i - 2, j, all_pieces[i][j], true])
	elif last_place.x + last_direction.x == i and last_place.y + last_direction.y == j + 1:
		matched_five.append([i, j + 1, all_pieces[i][j], true])
	elif last_place.x + last_direction.x == i and last_place.y + last_direction.y == j + 2:
		matched_five.append([i, j + 2, all_pieces[i][j], true])
	else:
		matched_five.append([i, j, all_pieces[i][j], true])

func this_is_column_1(i,j):
	if(all_pieces[i][j].type == "Column"):
		eraseColumn(i,j)
	if(all_pieces[i+1][j].type == "Column"):
		eraseColumn(i+1,j)
	if(all_pieces[i+2][j].type == "Column"):
		eraseColumn(i+2,j)
	if(all_pieces[i][j-1].type == "Column"):
		eraseColumn(i,j-1)
	if(all_pieces[i][j+1].type == "Column"):
		eraseColumn(i,j+1)

func this_is_row_1(i,j):
	if(all_pieces[i][j].type == "Row"):
		eraseRow(i,j)
	if(all_pieces[i+1][j].type == "Row"):
		eraseRow(i+1,j)
	if(all_pieces[i+2][j].type == "Row"):
		eraseRow(i+2,j)
	if(all_pieces[i][j-1].type == "Row"):
		eraseRow(i,j-1)
	if(all_pieces[i][j+1].type == "Row"):
		eraseRow(i,j+1)

func this_is_column_2(i,j):
	if all_pieces[i][j].type == "Column":
		eraseColumn(i, j)
	if all_pieces[i+1][j].type == "Column":
		eraseColumn(i+1, j)
	if all_pieces[i+2][j].type == "Column":
		eraseColumn(i+2, j)
	if all_pieces[i][j-2].type == "Column":
		eraseColumn(i, j-2)
	if all_pieces[i][j-1].type == "Column":
		eraseColumn(i, j-1)

func this_is_row_2(i,j):
	if all_pieces[i][j].type == "Row":
		eraseRow(i, j)
	if all_pieces[i+1][j].type == "Row":
		eraseRow(i+1, j)
	if all_pieces[i+2][j].type == "Row":
		eraseRow(i+2, j)
	if all_pieces[i][j-2].type == "Row":
		eraseRow(i, j-2)
	if all_pieces[i][j-1].type == "Row":
		eraseRow(i, j-1)

func this_is_column_3(i,j):
	if all_pieces[i][j].type == "Column":
		eraseColumn(i, j)
	if all_pieces[i+1][j].type == "Column":
		eraseColumn(i+1, j)
	if all_pieces[i+2][j].type == "Column":
		eraseColumn(i+2, j)
	if all_pieces[i][j+2].type == "Column":
		eraseColumn(i, j+2)
	if all_pieces[i][j+1].type == "Column":
		eraseColumn(i, j+1)
func this_is_row_3(i,j):
	if all_pieces[i][j].type == "Row":
		eraseRow(i, j)
	if all_pieces[i+1][j].type == "Row":
		eraseRow(i+1, j)
	if all_pieces[i+2][j].type == "Row":
		eraseRow(i+2, j)
	if all_pieces[i][j+2].type == "Row":
		eraseRow(i, j+2)
	if all_pieces[i][j+1].type == "Row":
		eraseRow(i, j+1)	

func this_is_column_4(i,j):
	if all_pieces[i][j].type == "Column":
		eraseColumn(i, j)
	if all_pieces[i + 1][j].type == "Column":
		eraseColumn(i + 1, j)
	if all_pieces[i ][j - 1].type == "Column":
		eraseColumn(i , j - 1)
	if all_pieces[i ][j - 2].type == "Column":
		eraseColumn(i , j - 2)
	if all_pieces[i - 1][j].type == "Column":
		eraseColumn(i - 1, j)

func this_is_row_4(i,j):
	if all_pieces[i][j].type == "Row":
		eraseRow(i, j)
	if all_pieces[i + 1][j].type == "Row":
		eraseRow(i + 1, j)
	if all_pieces[i ][j - 1].type == "Row":
		eraseRow(i , j - 1)
	if all_pieces[i ][j - 2].type == "Row":
		eraseRow(i , j - 2)
	if all_pieces[i - 1][j].type == "Row":
		eraseRow(i - 1, j)

func this_is_column_5(i,j):
	if all_pieces[i][j].type == "Column":
		eraseColumn(i, j)
	if all_pieces[i - 1][j].type == "Column":
		eraseColumn(i - 1, j)
	if all_pieces[i + 1][j].type == "Column":
		eraseColumn(i + 1, j)
	if all_pieces[i][j + 1].type == "Column":
		eraseColumn(i, j + 1)
	if all_pieces[i][j - 1].type == "Column":
		eraseColumn(i, j - 1)

func this_is_row_5(i,j):
	if all_pieces[i][j].type == "Row":
		eraseRow(i, j)
	if all_pieces[i + 1][j].type == "Row":
		eraseRow(i + 1, j)
	if all_pieces[i ][j - 1].type == "Row":
		eraseRow(i , j - 1)
	if all_pieces[i ][j - 2].type == "Row":
		eraseRow(i , j - 2)
	if all_pieces[i - 1][j].type == "Row":
		eraseRow(i - 1, j)

func this_is_column_6(i,j):
	if all_pieces[i][j].type == "Column":
		eraseColumn(i, j)
	if all_pieces[i - 1][j].type == "Column":
		eraseColumn(i - 1, j)
	if all_pieces[i - 2][j].type == "Column":
		eraseColumn(i - 2, j)
	if all_pieces[i][j - 1].type == "Column":
		eraseColumn(i, j - 1)
	if all_pieces[i][j - 2].type == "Column":
		eraseColumn(i, j - 2)

func this_is_row_6(i,j):
	if all_pieces[i][j].type == "Row":
		eraseRow(i, j)
	if all_pieces[i - 1][j].type == "Row":
		eraseRow(i - 1, j)
	if all_pieces[i - 2][j].type == "Row":
		eraseRow(i - 2, j)
	if all_pieces[i][j - 1].type == "Row":
		eraseRow(i, j - 1)
	if all_pieces[i][j - 2].type == "Row":
		eraseRow(i, j - 2)

func this_is_column_7(i,j):
	if all_pieces[i][j].type == "Column":
		eraseColumn(i, j)
	if all_pieces[i - 1][j].type == "Column":
		eraseColumn(i - 1, j)
	if all_pieces[i - 2][j].type == "Column":
		eraseColumn(i - 2, j)
	if all_pieces[i][j + 1].type == "Column":
		eraseColumn(i, j + 1)
	if all_pieces[i][j + 2].type == "Column":
		eraseColumn(i, j + 2)

func this_is_row_7(i,j):
	if all_pieces[i][j].type == "Row":
		eraseRow(i, j)
	if all_pieces[i - 1][j].type == "Row":
		eraseRow(i - 1, j)
	if all_pieces[i - 2][j].type == "Row":
		eraseRow(i - 2, j)
	if all_pieces[i][j + 1].type == "Row":
		eraseRow(i, j + 1)
	if all_pieces[i][j + 2].type == "Row":
		eraseRow(i, j + 2)

func matched_all8(i,j):
	all_pieces[i - 1][j].matched = true
	all_pieces[i - 1][j].dim()
	all_pieces[i - 2][j].matched = true
	all_pieces[i - 2][j].dim()
	all_pieces[i][j - 1].matched = true
	all_pieces[i][j - 1].dim()
	all_pieces[i][j + 1].matched = true
	all_pieces[i][j + 1].dim()
	all_pieces[i][j].matched = true
	all_pieces[i][j].dim()

func last_all8(i,j):
	if last_place.x == i and last_place.y == j:
		matched_five.append([i, j, all_pieces[i][j], true])
	elif last_place.x == i - 1 and last_place.y == j:
		matched_five.append([i - 1, j, all_pieces[i][j], true])
	elif last_place.x == i - 2 and last_place.y == j:
		matched_five.append([i - 2, j, all_pieces[i][j], true])
	elif last_place.x == i and last_place.y == j - 1:
		matched_five.append([i, j - 1, all_pieces[i][j], true])
	elif last_place.x == i and last_place.y == j + 1:
		matched_five.append([i, j + 1, all_pieces[i][j], true])
	elif last_place.x + last_direction.x == i and last_place.y + last_direction.y == j:
		matched_five.append([i, j, all_pieces[i][j], true])
	elif last_place.x + last_direction.x == i - 1 and last_place.y + last_direction.y == j:
		matched_five.append([i - 1, j, all_pieces[i][j], true])
	elif last_place.x + last_direction.x == i - 2 and last_place.y + last_direction.y == j:
		matched_five.append([i - 2, j, all_pieces[i][j], true])
	elif last_place.x + last_direction.x == i and last_place.y + last_direction.y == j - 1:
		matched_five.append([i, j - 1, all_pieces[i][j], true])
	elif last_place.x + last_direction.x == i and last_place.y + last_direction.y == j + 1:
		matched_five.append([i, j + 1, all_pieces[i][j], true])
	else:
		matched_five.append([i, j, all_pieces[i][j], true])

func this_is_column8(i,j):
	if all_pieces[i][j].type == "Column":
		eraseColumn(i, j)
	if all_pieces[i - 1][j].type == "Column":
		eraseColumn(i - 1, j)
	if all_pieces[i - 2][j].type == "Column":
		eraseColumn(i - 2, j)
	if all_pieces[i][j - 1].type == "Column":
		eraseColumn(i, j - 1)
	if all_pieces[i][j + 1].type == "Column":
		eraseColumn(i, j + 1)

func this_is_row8(i,j):
	if all_pieces[i][j].type == "Row":
		eraseRow(i, j)
	if all_pieces[i - 1][j].type == "Row":
		eraseRow(i - 1, j)
	if all_pieces[i - 2][j].type == "Row":
		eraseRow(i - 2, j)
	if all_pieces[i][j - 1].type == "Row":
		eraseRow(i, j - 1)
	if all_pieces[i][j + 1].type == "Row":
		eraseRow(i, j + 1)

func matched_all9(i,j):
	all_pieces[i - 1][j].matched = true
	all_pieces[i - 1][j].dim()
	all_pieces[i + 1][j].matched = true
	all_pieces[i + 1][j].dim()
	all_pieces[i][j + 1].matched = true
	all_pieces[i][j + 1].dim()
	all_pieces[i][j + 2].matched = true
	all_pieces[i][j + 2].dim()
	all_pieces[i][j].matched = true
	all_pieces[i][j].dim()

func last_all9(i,j):
	if last_place.x == i and last_place.y == j:
		matched_five.append([i, j, all_pieces[i][j], true])
	elif last_place.x == i - 1 and last_place.y == j:
		matched_five.append([i - 1, j, all_pieces[i][j], true])
	elif last_place.x == i + 1 and last_place.y == j:
		matched_five.append([i + 1, j, all_pieces[i][j], true])
	elif last_place.x == i and last_place.y == j + 1:
		matched_five.append([i, j + 1, all_pieces[i][j], true])
	elif last_place.x == i and last_place.y == j + 2:
		matched_five.append([i, j + 2, all_pieces[i][j], true])
	elif last_place.x + last_direction.x == i and last_place.y + last_direction.y == j:
		matched_five.append([i, j, all_pieces[i][j], true])
	elif last_place.x + last_direction.x == i - 1 and last_place.y + last_direction.y == j:
		matched_five.append([i - 1, j, all_pieces[i][j], true])
	elif last_place.x + last_direction.x == i + 1 and last_place.y + last_direction.y == j:
		matched_five.append([i + 1, j, all_pieces[i][j], true])
	elif last_place.x + last_direction.x == i and last_place.y + last_direction.y == j + 1:
		matched_five.append([i, j + 1, all_pieces[i][j], true])
	elif last_place.x + last_direction.x == i and last_place.y + last_direction.y == j + 2:
		matched_five.append([i, j + 2, all_pieces[i][j], true])
	else:
		matched_five.append([i, j, all_pieces[i][j], true])

func this_is_column9(i,j):
	if all_pieces[i][j].type == "Column":
		eraseColumn(i, j)
	if all_pieces[i - 1][j].type == "Column":
		eraseColumn(i - 1, j)
	if all_pieces[i + 1][j].type == "Column":
		eraseColumn(i + 1, j)
	if all_pieces[i][j + 1].type == "Column":
		eraseColumn(i, j + 1)
	if all_pieces[i][j + 2].type == "Column":
		eraseColumn(i, j + 2)

func this_is_row9(i,j):
	if all_pieces[i][j].type == "Row":
		eraseRow(i, j)
	if all_pieces[i - 1][j].type == "Row":
		eraseRow(i - 1, j)
	if all_pieces[i + 1][j].type == "Row":
		eraseRow(i + 1, j)
	if all_pieces[i][j + 1].type == "Row":
		eraseRow(i, j + 1)
	if all_pieces[i][j + 2].type == "Row":
		eraseRow(i, j + 2)

func find_matches():
	matched_four = []
	matched_five = []
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				var current_color = all_pieces[i][j].color
				if i < width - 2 and j < height - 1 and j>0:
					if all_pieces[i][j + 1] != null and all_pieces[i + 1][j] != null and all_pieces[i + 2][j] != null and all_pieces[i][j-1] != null:
						if all_pieces[i][j + 1].color == current_color and all_pieces[i + 1][j].color == current_color and all_pieces[i + 2][j].color == current_color and all_pieces[i][j-1].color == current_color and not all_pieces[i][j].matched and not all_pieces[i+1][j].matched and (not all_pieces[i+2][j].matched) and (not all_pieces[i+1][j+1].matched) and (not all_pieces[i][j+1].matched):
							matched_all1(i,j)
							if(all_pieces[i][j].type == "Adjacent" or all_pieces[i+1][j].type == "Adjacent" or all_pieces[i+2][j].type == "Adjacent" or all_pieces[i][j-1].type == "Adjacent" or all_pieces[i][j+1].type == "Adjacent"):
								eraseColor(all_pieces[i][j].color)
							last_all1(i,j)
							this_is_column_1(i,j)
							this_is_row_1(i,j)
				if i < width - 2 and j > 1:
					if all_pieces[i][j - 1] != null and all_pieces[i + 1][j] != null and all_pieces[i + 2][j] != null and all_pieces[i ][j - 2] != null:
						if all_pieces[i][j - 1].color == current_color and all_pieces[i + 1][j].color == current_color and all_pieces[i + 2][j].color == current_color and all_pieces[i ][j - 2].color == current_color and not all_pieces[i][j].matched and not all_pieces[i+1][j].matched and not all_pieces[i+2][j].matched and not all_pieces[i][j-2].matched and not all_pieces[i][j-1].matched:
							matched_all2(i,j)
							last_all2(i,j)
							
							if all_pieces[i][j].type == "Adjacent" or all_pieces[i+1][j].type == "Adjacent" or all_pieces[i+2][j].type == "Adjacent" or all_pieces[i][j-2].type == "Adjacent" or all_pieces[i][j-1].type == "Adjacent":
								eraseColor(all_pieces[i][j].color)
							this_is_column_2(i,j)
							this_is_row_2(i,j)

				if i < width - 2 and j < height - 2:
					if all_pieces[i][j + 1] != null and all_pieces[i + 1][j] != null and all_pieces[i + 2][j] != null and all_pieces[i][j + 2] != null:
						if all_pieces[i][j + 1].color == current_color and all_pieces[i + 1][j].color == current_color and all_pieces[i + 2][j].color == current_color and all_pieces[i][j + 2].color == current_color and not all_pieces[i][j].matched and not all_pieces[i+1][j].matched and not all_pieces[i+2][j].matched and not all_pieces[i][j+1].matched and not all_pieces[i][j+2].matched:
							matched_all3(i,j)
							last_all3(i,j)
							if all_pieces[i][j].type == "Adjacent" or all_pieces[i+1][j].type == "Adjacent" or all_pieces[i+2][j].type == "Adjacent" or all_pieces[i][j+2].type == "Adjacent" or all_pieces[i][j+1].type == "Adjacent":
								eraseColor(all_pieces[i][j].color)
							this_is_column_3(i,j)
							this_is_row_3(i,j)

				if i>0 and i < width - 1 and j > 1:
					
					if all_pieces[i][j - 1] != null and all_pieces[i + 1][j] != null and all_pieces[i-1][j] != null and all_pieces[i][j - 2] != null:
						if all_pieces[i][j - 1].color == current_color and all_pieces[i + 1][j].color == current_color and all_pieces[i - 1][j].color == current_color and all_pieces[i][j - 2].color == current_color and not all_pieces[i][j].matched and not all_pieces[i+1][j].matched and not all_pieces[i+1][j-1].matched and not all_pieces[i+1][j-2].matched and not all_pieces[i][j-1].matched:
							matched_all4(i,j)
							last_all4(i,j)
							
							if all_pieces[i][j].type == "Adjacent" or all_pieces[i + 1][j].type == "Adjacent" or all_pieces[i ][j - 1].type == "Adjacent" or all_pieces[i][j - 2].type == "Adjacent" or all_pieces[i- 1][j ].type == "Adjacent":
								eraseColor(all_pieces[i][j].color)
							this_is_column_4(i,j)
							this_is_row_4(i,j)
				
				if i > 0 and i < width - 1 and j < height - 1 and j > 0:
					if all_pieces[i - 1][j] != null and all_pieces[i + 1][j] != null and all_pieces[i][j + 1] != null and all_pieces[i][j - 1] != null:
						if all_pieces[i - 1][j].color == current_color and all_pieces[i + 1][j].color == current_color and all_pieces[i][j + 1].color == current_color and all_pieces[i][j - 1].color == current_color and not all_pieces[i][j].matched and not all_pieces[i-1][j].matched and not all_pieces[i+1][j].matched and not all_pieces[i][j+1].matched and not all_pieces[i][j-1].matched:
							matched_all5(i,j)
							last_all5(i,j)

							if all_pieces[i][j].type == "Adjacent" or all_pieces[i - 1][j].type == "Adjacent" or all_pieces[i + 1][j].type == "Adjacent" or all_pieces[i][j + 1].type == "Adjacent" or all_pieces[i][j - 1].type == "Adjacent":
								eraseColor(all_pieces[i][j].color)
							this_is_column_5(i,j)
							this_is_row_5(i,j)
				
				if i > 1 and j > 1:
					if all_pieces[i - 1][j] != null and all_pieces[i - 2][j] != null and all_pieces[i][j - 1] != null and all_pieces[i][j - 2] != null:
						if all_pieces[i - 1][j].color == current_color and all_pieces[i - 2][j].color == current_color and all_pieces[i][j - 1].color == current_color and all_pieces[i][j - 2].color == current_color and not all_pieces[i][j].matched and not all_pieces[i-1][j].matched and not all_pieces[i-2][j].matched and not all_pieces[i][j-1].matched and not all_pieces[i][j-2].matched:
							matched_all6(i,j)
							last_all6(i,j)
							if all_pieces[i][j].type == "Adjacent" or all_pieces[i - 1][j].type == "Adjacent" or all_pieces[i - 2][j].type == "Adjacent" or all_pieces[i][j - 1].type == "Adjacent" or all_pieces[i][j - 2].type == "Adjacent":
								eraseColor(all_pieces[i][j].color)
							this_is_column_6(i,j)
							this_is_row_6(i,j)
				
				if i > 1 and j<height - 2:
					if all_pieces[i - 1][j] != null and all_pieces[i - 2][j] != null and all_pieces[i][j + 1] != null and all_pieces[i][j + 2] != null:
						if all_pieces[i - 1][j].color == current_color and all_pieces[i - 2][j].color == current_color and all_pieces[i][j + 1].color == current_color and all_pieces[i][j + 2].color == current_color and not all_pieces[i][j].matched and not all_pieces[i-1][j].matched and not all_pieces[i-2][j].matched and not all_pieces[i][j+1].matched and not all_pieces[i][j+2].matched:
							matched_all7(i,j)
							last_all7(i,j)

							if all_pieces[i][j].type == "Adjacent" or all_pieces[i - 1][j].type == "Adjacent" or all_pieces[i - 2][j].type == "Adjacent" or all_pieces[i][j + 1].type == "Adjacent" or all_pieces[i][j + 2].type == "Adjacent":
								eraseColor(all_pieces[i][j].color)
							this_is_column_7(i,j)
							this_is_row_7(i,j)
				
				if i > 1 and j > 0 and j<height - 1:
					if all_pieces[i - 1][j] != null and all_pieces[i - 2][j] != null and all_pieces[i][j - 1] != null and all_pieces[i][j + 1] != null:
						if all_pieces[i - 1][j].color == current_color and all_pieces[i - 2][j].color == current_color and all_pieces[i][j - 1].color == current_color and all_pieces[i][j + 1].color == current_color and not all_pieces[i][j].matched and not all_pieces[i-1][j].matched and not all_pieces[i-2][j].matched and not all_pieces[i][j-1].matched and not all_pieces[i][j+1].matched:
							matched_all8(i,j)
							last_all8(i,j)
							if all_pieces[i][j].type == "Adjacent" or all_pieces[i - 1][j].type == "Adjacent" or all_pieces[i - 2][j].type == "Adjacent" or all_pieces[i][j - 1].type == "Adjacent" or all_pieces[i][j + 1].type == "Adjacent":
								eraseColor(all_pieces[i][j].color)
							this_is_column8(i,j)
							this_is_row8(i,j)
				
				if i > 0 and i < width -1 and j<height - 2:
					if all_pieces[i - 1][j] != null and all_pieces[i + 1][j] != null and all_pieces[i][j + 1] != null and all_pieces[i][j + 2] != null:
						if all_pieces[i - 1][j].color == current_color and all_pieces[i + 1][j].color == current_color and all_pieces[i][j + 1].color == current_color and all_pieces[i][j + 2].color == current_color and not all_pieces[i][j].matched and not all_pieces[i-1][j].matched and not all_pieces[i+1][j].matched and not all_pieces[i][j+1].matched and not all_pieces[i][j+2].matched:
							matched_all9(i,j)
							last_all9(i,j)

							if all_pieces[i][j].type == "Adjacent" or all_pieces[i - 1][j].type == "Adjacent" or all_pieces[i + 1][j].type == "Adjacent" or all_pieces[i][j + 1].type == "Adjacent" or all_pieces[i][j + 2].type == "Adjacent":
								eraseColor(all_pieces[i][j].color)
							this_is_column9(i,j)
							this_is_row9(i,j)
	for i in width:
		for j in height:    
			if all_pieces[i][j] != null:
				var current_color = all_pieces[i][j].color
				var matched = false
				matched = check_horizontal(i, j, current_color)
				if matched:
					continue
				matched = check_vertical(i, j, current_color)
				if matched:
					continue
	get_parent().get_node("destroy_timer").start()

func check_horizontal(i: int, j: int, color: String) -> bool:
	# Check for 5-piece horizontal match
	if i < width - 4:
		if all_pieces[i + 1][j] != null and all_pieces[i + 2][j] != null and all_pieces[i + 3][j] != null and all_pieces[i + 4][j] != null:
			if all_pieces[i + 1][j].color == color and all_pieces[i + 2][j].color == color and all_pieces[i + 3][j].color == color and all_pieces[i + 4][j].color == color:
				return process_match(i, j, i + 4, j, color)
	
	# Check for 4-piece horizontal match
	if i < width - 3:
		if all_pieces[i + 1][j] != null and all_pieces[i + 2][j] != null and all_pieces[i + 3][j] != null:
			if all_pieces[i + 1][j].color == color and all_pieces[i + 2][j].color == color and all_pieces[i + 3][j].color == color:
				return process_match(i, j, i + 3, j, color)
	
	# Check for 3-piece horizontal match
	if i < width - 2:
		if all_pieces[i + 1][j] != null and all_pieces[i + 2][j] != null:
			if all_pieces[i + 1][j].color == color and all_pieces[i + 2][j].color == color:
				return process_match(i, j, i + 2, j, color)
	return false

func check_vertical(i: int, j: int, color: String) -> bool:
	# Check for 5-piece vertical match
	if j <= height - 5:
		if all_pieces[i][j + 1] != null and all_pieces[i][j + 2] != null and all_pieces[i][j + 3] != null and all_pieces[i][j + 4] != null:
			if all_pieces[i][j + 1].color == color and all_pieces[i][j + 2].color == color and all_pieces[i][j + 3].color == color and all_pieces[i][j + 4].color == color:
				return process_match(i, j, i, j + 4, color)
	
	# Check for 4-piece vertical match
	if j <= height - 4:
		if all_pieces[i][j + 1] != null and all_pieces[i][j + 2] != null and all_pieces[i][j + 3] != null:
			if all_pieces[i][j + 1].color == color and all_pieces[i][j + 2].color == color and all_pieces[i][j + 3].color == color:
				return process_match(i, j, i, j + 3, color)
	
	# Check for 3-piece vertical match
	if j < height - 2:
		if all_pieces[i][j + 1] != null and all_pieces[i][j + 2] != null:
			if all_pieces[i][j + 1].color == color and all_pieces[i][j + 2].color == color:
				return process_match(i, j, i, j + 2, color)
	return false

func process_match(start_x: int, start_y: int, end_x: int, end_y: int, color: String) -> bool:
	var matched_pieces = []
	
	for i in range(start_x, end_x + 1):
		for j in range(start_y, end_y + 1):
			if all_pieces[i][j] != null:
				all_pieces[i][j].matched = true
				all_pieces[i][j].dim()
				matched_pieces.append(all_pieces[i][j])
				
			if all_pieces[i][j].type == "Adjacent":
				eraseColor(color)
			elif all_pieces[i][j].type == "Column":
				eraseColumn(i, j)
			elif all_pieces[i][j].type == "Row":
				eraseRow(i, j)
	
	if matched_pieces.size() == 5:
		matched_five.append([start_x, start_y, all_pieces[start_x][start_y], true])
	elif matched_pieces.size() == 4:
		matched_four.append([start_x, start_y, all_pieces[start_x][start_y], false])
	
	return true

func destroy_matched():
	var was_matched = false

	# Primero eliminamos las piezas que están marcadas como "matched"
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and all_pieces[i][j].matched:
				was_matched = true
				match_count += 1
				all_pieces[i][j].queue_free()
				all_pieces[i][j] = null

	# Luego manejamos las piezas especiales para los matches de 4
	for i in matched_four:
		var piece
		var piece_color = i[2].color
		var index = color_index.get(piece_color, -1) # Obtener el índice del color
		if i[3]:
			piece = vertical_pieces[index].instantiate()
			piece.type = "Column"
		else:
			piece = horizontal_pieces[index].instantiate()
			piece.type = "Row"
		add_child(piece)
		var x = i[0]
		var y = i[1]
		piece.position = grid_to_pixel(x,y)
		piece.color = i[2].color
		all_pieces[x][y] = piece
	
	for i in matched_five:
		var piece
		var piece_color = i[2].color
		var index = color_index.get(piece_color, -1) # Obtener el índice del color
		piece = all_directions_pieces[index].instantiate()
		piece.type = "Adjacent"
		add_child(piece)
		var x = i[0]
		var y = i[1]
		piece.position = grid_to_pixel(x,y)
		piece.color = i[2].color
		all_pieces[x][y] = piece
		
	move_checked = true
	if was_matched:
		get_parent().get_node("collapse_timer").start()
	else:
		swap_back()

		
func eraseColumn(i,j):
	for k in height:
		all_pieces[i][k].matched = true
		all_pieces[i][k].dim()
		if(all_pieces[i][k].type == "Row"):
			eraseRow(i,k)
		if(all_pieces[i][k].type == "Adjacent"):
			eraseColor(all_pieces[k][j].color)
		
func eraseRow(i,j):
	for k in width:
		all_pieces[k][j].matched = true
		all_pieces[k][j].dim()
		if(all_pieces[k][j].type == "Column"):
			eraseColumn(k,j)
		if(all_pieces[k][j].type == "Adjacent"):
			eraseColor(all_pieces[k][j].color)
		
func eraseColor(color):
	for i in width:
		for j in height:
			if all_pieces[i][j].color == color:
				all_pieces[i][j].matched = true
				all_pieces[i][j].dim()
				if(all_pieces[i][j].type == "Column"):
					eraseColumn(i,j)
				if(all_pieces[i][j].type == "Row"):
					eraseRow(i,j)
					
					
func collapse_columns():
	for i in width:
		for j in height:
			if all_pieces[i][j] == null:
				#print(i, j)
				# look above
				for k in range(j + 1, height):
					if all_pieces[i][k] != null:
						all_pieces[i][k].move(grid_to_pixel(i, j))
						all_pieces[i][j] = all_pieces[i][k]
						all_pieces[i][k] = null
						break
	get_parent().get_node("refill_timer").start()

func refill_columns():
	
	for i in width:
		for j in height:
			if all_pieces[i][j] == null:
				# random number
				var rand = randi_range(0, possible_pieces.size() - 1)
				# instance 
				var piece = possible_pieces[rand].instantiate()
				# repeat until no matches
				var max_loops = 100
				var loops = 0
				while (match_at(i, j, piece.color) and loops < max_loops):
					rand = randi_range(0, possible_pieces.size() - 1)
					loops += 1
					piece = possible_pieces[rand].instantiate()
				add_child(piece)
				piece.position = grid_to_pixel(i, j - y_offset)
				piece.move(grid_to_pixel(i, j))
				# fill array with pieces
				all_pieces[i][j] = piece
				
	check_after_refill()

func check_after_refill():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and match_at(i, j, all_pieces[i][j].color):
				find_matches()
				get_parent().get_node("destroy_timer").start()
				return
	state = MOVE
	
	move_checked = false

func _on_destroy_timer_timeout():
	#print("destroy")
	destroy_matched()

func _on_collapse_timer_timeout():
	#print("collapse")
	collapse_columns()

func _on_refill_timer_timeout():
	refill_columns()

	
func game_over():
	get_parent().get_node("bottom_ui").game_over()
	state = WAIT
	print("game over")


func _on_next_level_timeout() -> void:
	get_parent().get_node("second_timer").start()
	state = MOVE
	print("Next Level")
	get_parent().get_node("next_level").stop()


func _on_second_timer_timeout() -> void:
	get_parent().get_node("top_ui").decrease_count()
	
	if(time<=0):
		state = WAIT
		if score < score_goal:
			game_over()
		get_parent().get_node("second_timer").stop() 
	else:
		time -=1
		time = max(0,time)
		get_parent().get_node("second_timer").start()
