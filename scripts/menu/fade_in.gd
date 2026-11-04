extends ColorRect

## Ported from the Godot 3 addon: plays the fade_in animation, then tells the
## menu to swap scenes.

signal fade_finished

func fade_in() -> void:
	$AnimationPlayer.play("fade_in")

func _on_animation_finished(_anim_name: StringName) -> void:
	fade_finished.emit()
