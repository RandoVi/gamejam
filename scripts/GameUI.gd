extends Control

## Overlay HUD for every level. Instances the shared rhythm cue so the player
## can see the BeatManager clock and time jumps precisely.

const BEAT_INDICATOR_SCENE: PackedScene = preload("res://scenes/UI/BeatIndicator.tscn")

func _ready() -> void:
	if not has_node("BeatIndicator"):
		add_child(BEAT_INDICATOR_SCENE.instantiate())
