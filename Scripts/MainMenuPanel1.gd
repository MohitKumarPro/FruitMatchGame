extends "res://Scripts/BaseMenuPanel.gd"

signal play_pressed
signal setting_pressed



func _on_Button1_pressed():
	emit_signal("play_pressed") # Replace with function body.


func _on_Button2_pressed():
	emit_signal("setting_pressed") # Replace with function body.
