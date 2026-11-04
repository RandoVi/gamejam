extends Control

## Ported from the Godot 3 "Godot Main Menu" addon (Options scene).
## Music/Game sliders control the "Music" and "Game" audio buses;
## the checkbox toggles windowed/fullscreen; Back returns to the main menu.

const MAIN_MENU := "res://scenes/Menu/MainMenu.tscn"

@onready var _music_slider: HSlider = %MusicSlider
@onready var _game_slider: HSlider = %GameSlider
@onready var _fullscreen: CheckBox = %Fullscreen
@onready var _fade_in = $FadeIn
@onready var _ui_sound = $UISound

func _ready() -> void:
	var music_index := AudioServer.get_bus_index("Music")
	if music_index >= 0:
		_music_slider.value = AudioServer.get_bus_volume_db(music_index)
	
	var game_index := AudioServer.get_bus_index("Game")
	if game_index >= 0:
		_game_slider.value = AudioServer.get_bus_volume_db(game_index)
	
	var mode := DisplayServer.window_get_mode()
	_fullscreen.set_pressed_no_signal(
			mode == DisplayServer.WINDOW_MODE_FULLSCREEN
			or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)

func _on_music_slider_value_changed(value: float) -> void:
	var index := AudioServer.get_bus_index("Music")
	if index < 0:
		return
	AudioServer.set_bus_volume_db(index, value)
	AudioServer.set_bus_mute(index, value <= -30.0)

func _on_game_slider_value_changed(value: float) -> void:
	var index := AudioServer.get_bus_index("Game")
	if index < 0:
		return
	AudioServer.set_bus_volume_db(index, value)
	AudioServer.set_bus_mute(index, value <= -30.0)

func _on_fullscreen_toggled(toggled_on: bool) -> void:
	_ui_sound.play()
	DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_FULLSCREEN if toggled_on
			else DisplayServer.WINDOW_MODE_WINDOWED)

func _on_back_pressed() -> void:
	_ui_sound.play()
	_fade_in.show()
	_fade_in.fade_in()

func _on_fade_finished() -> void:
	get_tree().change_scene_to_file(MAIN_MENU)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
