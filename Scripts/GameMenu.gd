extends Control


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	$Main.slide_in()
	


func _on_Main_setting_pressed():
	$Main.slide_out()
	$settings.slide_in() # Replace with function body.


func _on_settings_back_button():
	$Main.slide_in()
	$settings.slide_out() # Replace with function body.


func _on_Main_play_pressed():
	get_tree().change_scene("res://Scenes/game_window.tscn") # Replace with function body.
