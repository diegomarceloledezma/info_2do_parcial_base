extends TextureRect

@onready var score_label = $MarginContainer/HBoxContainer/score_label
@onready var counter_label = $MarginContainer/HBoxContainer/counter_label
@onready var goal_label = $MarginContainer/HBoxContainer/goal_label

var current_score = 0
var current_count = 0
var current_goal = 0

func increment_counter(increment):
	current_score += increment
	score_label.text = str(current_score)

func decrease_count():
	current_count -= 1
	current_count = max(0, current_count)
	counter_label.text = str(current_count)

func initCurrentCount(init):
	current_count = init
	counter_label.text = str(current_count)

func initCurrentScore(init):
	current_score = init
	score_label.text = str(current_score)

# Nueva función para inicializar el goal
func initGoal(init):
	current_goal = init
	goal_label.text = "Objetivo: 
		" + str(current_goal)

# Nueva función para actualizar el goal al cambiar de nivel
func updateGoal(new_goal):
	current_goal = new_goal
	goal_label.text = "Objetivo: 
		" + str(current_goal)
