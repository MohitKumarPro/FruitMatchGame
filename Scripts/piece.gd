extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

export (String) var color;
export (Texture) var row_texture
export (Texture) var column_texture
export (Texture) var adjacent_texture
export (Texture) var color_bomb_texture


var is_row_bomb = false
var is_column_bomb = false
var is_adjacent_bomb = false
var is_color_bomb = false

var move_tween;
var matched = false;

# Called when the node enters the scene tree for the first time.
func _ready():
	move_tween = get_node("move_tween");
	# Replace with function body.

func move(target):
	move_tween.interpolate_property(self, "position", position, target, .3, Tween.TRANS_ELASTIC, Tween.EASE_OUT);
	move_tween.start();
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
func make_row_bomb():
	is_row_bomb = true
	$Sprite2.texture = row_texture
	$Sprite2.modulate = Color(1,1,1,1)

func make_column_bomb():
	is_column_bomb = true
	$Sprite2.texture = column_texture
	$Sprite2.modulate = Color(1,1,1,1)

func make_adjacent_bomb():
	is_adjacent_bomb = true
	$Sprite2.texture = adjacent_texture
	$Sprite2.modulate = Color(1,1,1,1)

func make_color_bomb():
	is_color_bomb = true
	$Sprite2.texture = color_bomb_texture
	$Sprite2.modulate = Color(1,1,1,1)
	color = "Color"

func dim():
	var sprite = get_node("Sprite2");
	sprite.modulate = Color(1,1,1,.2);
