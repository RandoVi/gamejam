extends Control

## Ported from the Godot 3 "Godot Main Menu" addon.
## Start -> Level_01, Options -> Options.tscn, Quit -> exit.
## The fade covers the screen, then the scene is swapped.

const LEVEL_SCENE := "res://scenes/Levels/Level_01.tscn"
const OPTIONS_SCENE := "res://scenes/Menu/Options.tscn"

@onready var _fade_in = $FadeIn
@onready var _ui_sound = $UISound

var _next_scene: String = ""

func _ready() -> void:
	$Margin/Menu/CenterRow/Buttons/StartGame.grab_focus()

func _on_start_pressed() -> void:
	_change_scene(LEVEL_SCENE)

func _on_options_pressed() -> void:
	_change_scene(OPTIONS_SCENE)

func _on_quit_pressed() -> void:
	_ui_sound.play()
	get_tree().quit()

func _change_scene(path: String) -> void:
	_next_scene = path
	_ui_sound.play()
	_fade_in.show()
	_fade_in.fade_in()

func _on_fade_finished() -> void:
	if _next_scene.is_empty():
		return
	get_tree().change_scene_to_file(_next_scene)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
