extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export (int) var width;
export (int) var height;
export (int) var x_start;
export (int) var y_start;
export (int) var offset;
export (int) var y_offset;

export (PoolVector2Array) var empty_spaces
export (PoolVector2Array) var ice_pieces
export (PoolVector2Array) var lock_spaces
export (PoolVector2Array) var  concrete_spaces
export (PoolVector2Array) var slime_spaces

var damage_slime = false
#obstakal signal
signal make_ice
signal damage_ice
signal make_lock
signal damage_lock
signal make_concrete
signal damage_concrete
signal make_slime
signal damage_slime
# the piece array
var possible_pieces = [
	preload("res://Scenes/apple_piece.tscn"),
	preload("res://Scenes/banana_piece.tscn"),
	preload("res://Scenes/berry_piece.tscn"),
	preload("res://Scenes/coconut_piece.tscn"),
	preload("res://Scenes/melon_piece.tscn"),
	preload("res://Scenes/orange_piece.tscn")
];
# state machine
enum {wait, move}
var state 
var first_touch = Vector2(0,0);
var final_touch = Vector2(0,0);
var controlling = false;

#soring variable 
signal update_score
signal setup_max_score
export (int) var max_score
export (int) var piece_value
var streak = 1

#counter variable 
signal update_counter
export (int) var current_counter_value
export (bool)  var is_moves 
signal game_over
#was a color bomb used
var color_bomb_used = false

#sinker
export (PackedScene) var sinker_piece
export (bool) var sinkers_in_scene
export (int) var max_sinkers
var current_sinkers = 0

# the currect pieces in the scene
var all_pieces = []
var current_matches = []

#Effect 
var particle_effect = preload("res://Scenes/ParticleEffect.tscn")
var animated_effect = preload("res://Scenes/AnimatedExplosion.tscn")

#swap variables
var piece_one = null
var piece_two = null
var last_place = Vector2(0,0)
var last_direction = Vector2(0,0)
var move_checked = false
# Called when the node enters the scene tree for the first time.

func _ready():
	randomize()
	state = move
	all_pieces = make_2d_array();
	if sinkers_in_scene:
		spawn_sinkers(max_sinkers)
	spawn_pieces(); # Replace with function body.
	spawn_ice()
	spawn_locks()
	spawn_concrete()
	spawn_slime()
	emit_signal("update_counter", current_counter_value)
	emit_signal("setup_max_score",max_score)
	if !is_moves:
		$Timer.start()
		

func restricted_fill(place):
	if is_in_array(empty_spaces, place):
		return true
	if is_in_array(concrete_spaces, place):
		return true
	if is_in_array(slime_spaces, place):
		return true
	return false

func restricted_move(place):
	if is_in_array(lock_spaces, place):
		return true
	return false

func is_in_array(array, item):
	for i in array.size():
		if array[i] == item:
			return true
	return false

func make_2d_array():
	var array = []
	for i in width:
		array.append([]);
		for j in height:
			array[i].append(null);
	return array;
			
func spawn_pieces():
	for i in width:
		for j in height:
			if !restricted_fill(Vector2(i,j)) and all_pieces[i][j] == null:
				var rand = floor(rand_range(0,possible_pieces.size()));
				
				var piece = possible_pieces[rand].instance();
				var loops = 0
				while(match_at(i,j,piece.color) and loops < 50):
					rand = floor(rand_range(0,possible_pieces.size()));
					loops+=1
					piece = possible_pieces[rand].instance();
				add_child(piece);
				piece.position = grid_to_pixel(i,j);
				all_pieces[i][j] = piece;

func is_piece_sinker(column, row):
	if all_pieces[column][row] != null:
		if all_pieces[column][row].color == "None":
			return true
	return false

func spawn_ice():
	for i in ice_pieces.size():
		emit_signal("make_ice",ice_pieces[i])

func spawn_locks():
	for i in lock_spaces.size():
		emit_signal("make_lock",lock_spaces[i])

func spawn_concrete():
	for i in concrete_spaces.size():
		emit_signal("make_concrete",concrete_spaces[i])

func spawn_slime():
	for i in slime_spaces.size():
		emit_signal("make_slime",slime_spaces[i])

func spawn_sinkers(number_to_spawn):
	for i in number_to_spawn:
		var column = floor(rand_range(0,width))
		while all_pieces[column][height - 1] != null or restricted_fill(Vector2(column, height - 1)):
			column = floor(rand_range(0,width))
		var current = sinker_piece.instance()
		add_child(current)
		current.position = grid_to_pixel(column, height - 1)
		all_pieces[column][height -1] = current
		current_sinkers += 1

func match_at(i,j,color):
	if i > 1:
		if all_pieces[i-1][j] != null && all_pieces[i-2][j] != null:
			if all_pieces[i-1][j].color == color && all_pieces[i-2][j].color == color:
				return true;
	if j > 1:
		if all_pieces[i][j-1] != null && all_pieces[i][j-2] != null:
			if all_pieces[i][j-1].color == color && all_pieces[i][j-2].color == color:
				return true;

func grid_to_pixel(column,row):
	var new_x = x_start + offset * column;
	var new_y = y_start + -offset * row;
	return Vector2(new_x,new_y);

func pixel_to_grid(pixel_x,pixel_y):
	var new_x = round((pixel_x - x_start)/offset);
	var new_y = round((pixel_y - y_start)/-offset);
	return Vector2(new_x,new_y)
	
func is_in_grid(grid_position):
	if grid_position.x >= 0 && grid_position.x < width:
		if grid_position.y >=0 && grid_position.y < height:
			return true;
	return false;
	
func touch_input():
	if Input.is_action_just_pressed("ui_touch"):
		if is_in_grid(pixel_to_grid(get_global_mouse_position().x,get_global_mouse_position().y)):
			first_touch = pixel_to_grid(get_global_mouse_position().x, get_global_mouse_position().y);
			controlling = true;
			
	if Input.is_action_just_released("ui_touch"):
		if is_in_grid(pixel_to_grid(get_global_mouse_position().x,get_global_mouse_position().y)) && controlling:
			controlling = false;
			final_touch = pixel_to_grid(get_global_mouse_position().x, get_global_mouse_position().y);
			touch_difference(first_touch, final_touch);

func swap_pieces(column, row, direction):
	var first_piece = all_pieces[column][row];
	var other_piece = all_pieces[column + direction.x][row + direction.y];
	if first_piece != null && other_piece != null:
		if !restricted_move(Vector2(column, row)) && !restricted_move(Vector2(column, row) + direction):
			if is_color_bomb(first_piece, other_piece):
				if first_piece.color =="Color":
					match_color(other_piece.color)
					match_and_dim(first_piece)
					add_to_array(Vector2(column,row))
				else:
					match_color(first_piece.color)
					match_and_dim(other_piece)
					add_to_array(Vector2(column + direction.x,row + direction.y))
			store_info(first_piece, other_piece, Vector2(column, row), direction)
			state = wait
			all_pieces[column][row] = other_piece;
			all_pieces[column + direction.x][row + direction.y] = first_piece;
			first_piece.move(grid_to_pixel(column + direction.x, row + direction.y));
			other_piece.move(grid_to_pixel(column,row));
			if !move_checked:
				find_matches();

func is_color_bomb(piece_one, piece_two):
	if piece_one.color == "Color" or piece_two.color == "Color":
		color_bomb_used = true
		return true
	return false

func store_info(first_piece, other_piece, place, direction):
	piece_one = first_piece
	piece_two = other_piece
	last_place = place
	last_direction = direction
	
func swap_back():
	if piece_one != null && piece_two != null:
		swap_pieces(last_place.x, last_place.y, last_direction)
	state = move
	move_checked = false
	
func touch_difference(grid_1, grid_2):
	var difference = grid_1 - grid_2
	if abs(difference.x) > abs(difference.y):
		if difference.x > 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(-1,0));
		elif difference.x < 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(1,0));
	elif abs(difference.y) > abs(difference.x):
		if difference.y > 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(0,-1));
		elif difference.y < 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(0,1));
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if state == move:
		touch_input()

func find_matches():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and !is_piece_sinker(i, j):
				var current_color = all_pieces[i][j].color;
				if i > 0 && i < width - 1 :
					if !is_piece_null(i-1,j) && !is_piece_null(i+1,j):
						if all_pieces[i-1][j].color == current_color && all_pieces[i+1][j].color == current_color:
							match_and_dim(all_pieces[i-1][j])
							match_and_dim(all_pieces[i][j])
							match_and_dim(all_pieces[i+1][j])
							add_to_array(Vector2(i,j))
							add_to_array(Vector2(i + 1,j))
							add_to_array(Vector2(i - 1,j))
				if j > 0 && j < height - 1 :
					if !is_piece_null(i,j-1) && !is_piece_null(i,j+1):
						if all_pieces[i][j-1].color == current_color && all_pieces[i][j+1].color == current_color:
							match_and_dim(all_pieces[i][j-1])
							match_and_dim(all_pieces[i][j])
							match_and_dim(all_pieces[i][j+1])
							add_to_array(Vector2(i,j))
							add_to_array(Vector2(i,j + 1))
							add_to_array(Vector2(i,j - 1))
	get_bombed_pieces()
	get_parent().get_node("destroy_timer").start();

func get_bombed_pieces():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				if all_pieces[i][j].matched:
					if all_pieces[i][j].is_column_bomb:
						match_all_in_column(i)
					elif all_pieces[i][j].is_row_bomb:
						match_all_in_row(j)
					elif all_pieces[i][j].is_adjacent_bomb:
						find_adjacent_pieces(i,j)

func add_to_array(value, array_to_add = current_matches):
	if !array_to_add.has(value):
		array_to_add.append(value)

func is_piece_null(column, row):
	if all_pieces[column][row] == null:
		return true
	return false
	
func match_and_dim(item):
	item.matched = true
	item.dim()

func find_bombs():
	for i in current_matches.size():
		#iterate through current matches array
		var current_column = current_matches[i].x
		#store some values this match
		var current_row = current_matches[i].y
		var current_color = all_pieces[current_column][current_row].color
		var col_matched = 0
		var row_matched = 0
		#iterate over the current matches to check for column and row and color
		for j in current_matches.size():
			var this_column = current_matches[j].x
			var this_row = current_matches[j].y
			var this_color = all_pieces[current_column][current_row].color
			if this_column == current_column and current_color == this_color:
				col_matched += 1
			if this_row == current_row and this_color == current_color:
				row_matched += 1
		if col_matched == 5 or row_matched == 5:
			make_bomb(3,current_color)
			return
		elif col_matched >= 3 and row_matched >= 3:
			make_bomb(0, current_color)
			return
		elif col_matched == 4:
			make_bomb(1, current_color)
			return
		elif row_matched == 4:
			make_bomb(2, current_color)
			return

func make_bomb(bomb_type, color):
	#iterate over current matches 
	for i in current_matches.size():
		var current_column = current_matches[i].x
		var current_row = current_matches[i].y
		if all_pieces[current_column][current_row] == piece_one and piece_one.color == color:
			#make piece one a bomb
			piece_one.matched = false
			change_bomb(bomb_type, piece_one)
		if all_pieces[current_column][current_row] == piece_two and piece_two.color == color:
			piece_two.matched = false
			change_bomb(bomb_type, piece_two)

func change_bomb(bomb_type, piece):
	if bomb_type == 0:
		piece.make_adjacent_bomb()
	elif bomb_type == 1:
		piece.make_row_bomb()
	elif bomb_type == 2:
		piece.make_column_bomb()
	elif bomb_type == 3:
		piece.make_color_bomb()
		
func destroy_matched():
	find_bombs()
	var was_matched = false
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				if all_pieces[i][j].matched:
					damage_special(i,j)
					was_matched = true
					all_pieces[i][j].queue_free();
					all_pieces[i][j] = null
					make_effect(particle_effect,i,j)
					make_effect(animated_effect,i,j)
					emit_signal("update_score", piece_value * streak)
	move_checked = true
	if was_matched:
		get_parent().get_node("collapse_timer").start();
	else:
		swap_back()
	current_matches.clear()

func make_effect(effect, column, row):
	var current = effect.instance()
	current.position = grid_to_pixel(column, row)
	add_child(current)

func check_concrete(column, row):
	#check right
	if column < width - 1:
		emit_signal("damage_concrete", Vector2(column + 1, row))
	#check left
	if column > 0:
		emit_signal("damage_concrete", Vector2(column - 1, row))
	#check up
	if row < height - 1:
		emit_signal("damage_concrete", Vector2(column, row + 1))
	#check down
	if row > 0:
		emit_signal("damage_concrete", Vector2(column, row - 1))

 
func check_slime(column, row):
	#check right
	if column < width - 1:
		emit_signal("damage_slime", Vector2(column + 1, row))
	#check left
	if column > 0:
		emit_signal("damage_slime", Vector2(column - 1, row))
	#check up
	if row < height - 1:
		emit_signal("damage_slime", Vector2(column, row + 1))
	#check down
	if row > 0:
		emit_signal("damage_slime", Vector2(column, row - 1))

func damage_special(column, row):
	emit_signal("damage_ice",Vector2(column, row))
	emit_signal("damage_lock",Vector2(column, row))
	check_concrete(column, row)
	check_slime(column, row)

func match_color(color):
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and !is_piece_sinker(i, j):
				if all_pieces[i][j].color == color:
					match_and_dim(all_pieces[i][j])
					add_to_array(Vector2(i,j))

func clear_board():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and !is_piece_sinker(i,j):
				match_and_dim(all_pieces[i][j])
				add_to_array(Vector2(i,j))

func collapse_columns():
	for i in width:
		for j in height:
			if all_pieces[i][j] == null && !restricted_fill(Vector2(i,j)):
				for k in range(j+1, height):
					if all_pieces[i][k] != null:
						all_pieces[i][k].move(grid_to_pixel(i,j))
						all_pieces[i][j] = all_pieces[i][k]
						all_pieces[i][k] = null
						break
	destroy_sinkers()
	get_parent().get_node("refil_timer").start()

func refil_columns():
	if current_sinkers < max_sinkers:
		spawn_sinkers(max_sinkers - current_sinkers)
	streak += 1
	for i in width:
		for j in height:
			if all_pieces[i][j] == null && !restricted_fill(Vector2(i,j)):
				var rand = floor(rand_range(0,possible_pieces.size()));
				var piece = possible_pieces[rand].instance();
				var loops = 0
				while(match_at(i,j,piece.color) && loops < 100):
					rand = floor(rand_range(0,possible_pieces.size()));
					loops+=1
					piece = possible_pieces[rand].instance();
				add_child(piece);
				piece.position = grid_to_pixel(i,j - y_offset);
				piece.move(grid_to_pixel(i,j))
				all_pieces[i][j] = piece;
	after_refil()
	
func after_refil():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				if match_at(i, j, all_pieces[i][j].color) or all_pieces[i][j].matched:
					find_matches()
					get_parent().get_node("destroy_timer").start()
					return 
	if !damage_slime:
		generate_slime()
	state = move
	streak = 1
	move_checked = false
	damage_slime = false
	color_bomb_used = false
	if is_moves:
		current_counter_value -= 1
		emit_signal("update_counter")
		if current_counter_value == 0:
			declare_game_over()

func generate_slime():
	if slime_spaces.size() > 0:
		var slime_made = false
		var tracker = 0
		while !slime_made and tracker < 100:
			var random_num = floor(rand_range(0, slime_spaces.size()))
			var curr_x = slime_spaces[random_num].x
			var curr_y = slime_spaces[random_num].y
			var neighbor = find_normal_neighbour(curr_x,curr_y)
			if neighbor != null:
				#turn that neighbor into slime
				#remove that piece
				all_pieces[neighbor.x][neighbor.y].queue_free()
				#et it to null
				all_pieces[neighbor.x][neighbor.y] = null
				#add new spot into array oos alime 
				slime_spaces.append(Vector2(neighbor.x,neighbor.y))
				#send the signal to slime holder
				emit_signal("make_slime",Vector2(neighbor.x,neighbor.y))
				slime_made = true
			tracker += 1

func find_normal_neighbour(column, row):
	#check right first
	if is_in_grid(Vector2(column + 1, row)):
		if all_pieces[column + 1][row] != null and !is_piece_sinker(column + 1, row):
			return Vector2(column + 1, row)
	#check left
	if is_in_grid(Vector2(column - 1, row)):
		if all_pieces[column - 1][row] != null and !is_piece_sinker(column - 1, row):
			return Vector2(column - 1, row)
	#check up
	if is_in_grid(Vector2(column, row + 1)):
		if all_pieces[column][row + 1] != null and !is_piece_sinker(column, row + 1):
			return Vector2(column, row + 1)
	#check down
	if is_in_grid(Vector2(column, row - 1)):
		if all_pieces[column][row - 1] != null and !is_piece_sinker(column, row - 1):
			return Vector2(column, row - 1)
	return null

func match_all_in_column(column):
	for i in height:
		if all_pieces[column][i] != null and !is_piece_sinker(column, i):
			if all_pieces[column][i].is_row_bomb:
				match_all_in_row(i)
			if all_pieces[column][i].is_adjacent_bomb:
				find_adjacent_pieces(column, i)
			all_pieces[column][i].matched = true
			
func match_all_in_row(row):
	for i in width:
		if all_pieces[i][row] != null and !is_piece_sinker(i,row):
			if all_pieces[i][row].is_column_bomb:
				match_all_in_column(i)
			if all_pieces[i][row].is_adjacent_bomb:
				find_adjacent_pieces(i, row)
			all_pieces[i][row].matched = true

func find_adjacent_pieces(column, row):
	for i in range(-1, 2):
		for j in range(-1, 2):
			if is_in_grid(Vector2(column + i, row + j)):
				if all_pieces[column + i][row + j] != null and !is_piece_sinker(column + i, row + j):
					if all_pieces[column][i].is_row_bomb:
						match_all_in_row(i)
					if all_pieces[i][row].is_column_bomb:
						match_all_in_column(i)
					all_pieces[column + i][row + j].matched = true

func destroy_sinkers():
	for i in width:
		if all_pieces[i][0] != null:
			if all_pieces[i][0].color == "None":
				all_pieces[i][0].matched = true
				current_sinkers -= 1

func _on_destroy_timer_timeout():
	destroy_matched(); # Replace with function body.


func _on_collapse_timer_timeout():
	collapse_columns(); # Replace with function body.


func _on_refil_timer_timeout():
	refil_columns() # Replace with function body.


func _on_lock_holder_remove_lock(place):
	for i in range(lock_spaces.size() - 1, -1, -1):
		if lock_spaces[i] == place:
			lock_spaces.remove(i)
# Replace with function body.


func _on_concrete_holder_remove_concrete(place):
	for i in range(concrete_spaces.size() - 1, -1, -1):
		if concrete_spaces[i] == place:
			concrete_spaces.remove(i)
	 # Replace with function body.


func _on_slime_holder_remove_slime(place):
	damage_slime = true
	for i in range(slime_spaces.size() - 1, -1, -1):
		if slime_spaces[i] == place:
			slime_spaces.remove(i) # Replace with function body.


func _on_Timer_timeout():
	current_counter_value -= 1
	emit_signal("update_counter") # Replace with function body.
	if current_counter_value == 0:
		declare_game_over()
		$Timer.stop()

func declare_game_over():
	emit_signal("game_over")
	state = wait
