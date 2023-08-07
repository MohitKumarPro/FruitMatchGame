extends "res://Scripts/BaseMenuPanel.gd"

signal sound_change
signal back_button

func _on_Button1_pressed():
	emit_signal("sound_change") # Replace with function body.


func _on_Button2_pressed():
	emit_signal("back_button") # Replace with function body.
