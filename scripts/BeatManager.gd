extends Node

## Global beat clock for rhythm-driven gameplay.
##
## The clock advances in _process and emits a beat every beat_length seconds.
## Jumps are graded against the nearest beat:
##   - STRONG  : on a beat whose index is `strong_beat_index` in the bar
##               (default: the 4th beat of a 4/4 bar)
##   - NORMAL  : on any other beat
##   - OFFBEAT : outside `hit_window` seconds of any beat
##
## This node is registered as the `BeatManager` autoload. It intentionally has
## no class_name because the autoload singleton already uses that name.

signal beat(beat_index: int, is_strong: bool)
signal strong_beat(beat_index: int)

enum JumpTier {
	OFFBEAT = 0,
	NORMAL = 1,
	STRONG = 2,
}

@export_range(30.0, 300.0, 1.0) var bpm: float = 80.0
@export_range(1, 16, 1) var beats_per_bar: int = 4

## Zero-based index of the strong beat inside a bar.
## 3 = the 4th beat of a 4/4 bar; 0 = the first beat of the bar.
@export_range(0, 15, 1) var strong_beat_index: int = 3

## Maximum timing error, in seconds, still counted as being "on the beat".
@export_range(0.0, 0.5, 0.005) var hit_window: float = 0.1

## Seconds elapsed since the clock started.
var song_position: float = 0.0

var _next_beat_index: int = 0

func _ready() -> void:
	# Emit the first beat immediately so UI/animations can start on it.
	_emit_beat(0)
	_next_beat_index = 1

func _process(delta: float) -> void:
	if bpm <= 0.0:
		return
	
	song_position += delta
	var beat_length: float = get_beat_length()
	
	# Emit every beat crossed during this frame. The loop also covers a large
	# delta after a stall instead of silently skipping beats.
	while song_position >= _next_beat_index * beat_length:
		_emit_beat(_next_beat_index)
		_next_beat_index += 1

func _emit_beat(index: int) -> void:
	var strong: bool = is_strong_beat_index(index)
	beat.emit(index, strong)
	if strong:
		strong_beat.emit(index)

func get_beat_length() -> float:
	return 60.0 / bpm if bpm > 0.0 else 0.0

## Zero-based beat that is closest to the current time.
func get_nearest_beat_index() -> int:
	var beat_length: float = get_beat_length()
	if beat_length <= 0.0:
		return 0
	return roundi(song_position / beat_length)

## How far the clock is from the nearest beat, in seconds.
func get_distance_to_beat() -> float:
	var beat_length: float = get_beat_length()
	if beat_length <= 0.0:
		return 0.0
	var phase: float = fmod(song_position, beat_length)
	return minf(phase, beat_length - phase)

## 0.0 at a beat, 0.5 halfway between beats.
func get_beat_phase() -> float:
	var beat_length: float = get_beat_length()
	if beat_length <= 0.0:
		return 0.0
	return fmod(song_position, beat_length) / beat_length

func is_strong_beat_index(index: int) -> bool:
	var beats: int = maxi(beats_per_bar, 1)
	return posmod(index, beats) == strong_beat_index

func is_on_beat() -> bool:
	return bpm > 0.0 and get_distance_to_beat() <= hit_window

func is_strong_beat() -> bool:
	return is_on_beat() and is_strong_beat_index(get_nearest_beat_index())

func get_jump_tier() -> JumpTier:
	if not is_on_beat():
		return JumpTier.OFFBEAT
	if is_strong_beat():
		return JumpTier.STRONG
	return JumpTier.NORMAL

## Restart the clock at time 0 and emit the first beat.
func reset() -> void:
	song_position = 0.0
	_next_beat_index = 0
	_emit_beat(0)
	_next_beat_index = 1

## Jump the clock to a given position without emitting skipped beats.
func seek(position: float) -> void:
	song_position = maxf(position, 0.0)
	var beat_length: float = get_beat_length()
	if beat_length <= 0.0:
		_next_beat_index = 0
	else:
		_next_beat_index = int(floor(song_position / beat_length)) + 1

## Change the tempo and keep the clock at the same position.
func set_bpm(new_bpm: float) -> void:
	bpm = maxf(new_bpm, 0.0)
	var beat_length: float = get_beat_length()
	if beat_length <= 0.0:
		_next_beat_index = 0
	else:
		_next_beat_index = int(floor(song_position / beat_length)) + 1
