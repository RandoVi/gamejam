class_name BeatIndicator
extends Control

## On-screen rhythm lane for the BeatManager clock.
##
## Every value is derived from BeatManager.song_position — the same clock the
## jump grading reads — so the cue can never drift from the rules:
##   * the vertical playhead reaches a tick exactly on each beat,
##   * the translucent band around each tick is the real `hit_window`,
##   * the JUMP badge lights up while a jump would be graded ON BEAT,
##   * the badge turns gold on the strong beat and shows the live tier.
##
## The scene is instanced by GameUI, so every level gets it.

@export var accent_color: Color = Color("4ade80")
@export var strong_color: Color = Color("fbbf24")
@export var offbeat_color: Color = Color("94a3b8")
@export var dim_color: Color = Color("64748b")
@export_range(1.0, 20.0) var flash_decay: float = 4.0

@export_group("Layout")
@export var lane_y: float = 46.0
@export var chips_y: float = 90.0
@export var badge_center: Vector2 = Vector2(58.0, 54.0)
@export var badge_radius: float = 36.0
@export var lane_left: float = 116.0
@export var lane_right_margin: float = 22.0

var _beat_manager
var _panel_style: StyleBoxFlat
var _flash: float = 0.0
var _strong_flash: float = 0.0
var _last_beat_index: int = 0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	_panel_style = StyleBoxFlat.new()
	_panel_style.bg_color = Color(0.035, 0.047, 0.078, 0.86)
	_panel_style.set_corner_radius_all(12)
	_panel_style.set_border_width_all(2)
	_panel_style.border_color = Color(1.0, 1.0, 1.0, 0.08)
	
	_beat_manager = get_node_or_null("/root/BeatManager")
	if _beat_manager and _beat_manager.has_signal("beat"):
		_beat_manager.beat.connect(_on_beat)

func _process(delta: float) -> void:
	_flash = maxf(_flash - flash_decay * delta, 0.0)
	_strong_flash = maxf(_strong_flash - flash_decay * delta, 0.0)
	queue_redraw()

func _on_beat(beat_index: int, is_strong: bool) -> void:
	_last_beat_index = beat_index
	_flash = 1.0
	if is_strong:
		_strong_flash = 1.0

func _draw() -> void:
	_panel_style.border_color = Color(1.0, 1.0, 1.0, 0.08 + 0.30 * _strong_flash + 0.12 * _flash)
	draw_style_box(_panel_style, Rect2(Vector2.ZERO, size))
	
	if _beat_manager == null:
		_draw_centered("BeatManager autoload missing", size.x * 0.5, size.y * 0.5 + 5.0, 14, dim_color)
		return
	
	var beat_length: float = float(_beat_manager.get_beat_length())
	if beat_length <= 0.0:
		return
	
	var beats: int = maxi(int(_beat_manager.beats_per_bar), 1)
	var lane_width: float = maxf(size.x - lane_right_margin - lane_left, 40.0)
	var on_beat: bool = bool(_beat_manager.is_on_beat())
	var tier: int = int(_beat_manager.get_jump_tier())
	var tier_color: Color = offbeat_color
	if tier == 1:
		tier_color = accent_color
	elif tier == 2:
		tier_color = strong_color
	
	# One bar spans the lane, so the playhead lands on tick i exactly on beat i.
	var bar_length: float = beat_length * float(beats)
	var song_position: float = float(_beat_manager.song_position)
	var bar_phase: float = fmod(song_position, bar_length) / bar_length
	var playhead_x: float = lane_left + bar_phase * lane_width
	
	# Header.
	_draw_text("RHYTHM  ·  %d BPM  ·  %d beats/bar" % [roundi(float(_beat_manager.bpm)), beats],
			Vector2(lane_left, 21.0), 12, Color(1.0, 1.0, 1.0, 0.55))
	var window_ms: int = roundi(float(_beat_manager.hit_window) * 1000.0)
	_draw_text("±%d ms window" % window_ms, Vector2(lane_left, 21.0), 12,
			Color(1.0, 1.0, 1.0, 0.38), HORIZONTAL_ALIGNMENT_RIGHT, lane_width)
	
	# Lane track.
	draw_rect(Rect2(lane_left, lane_y - 3.0, lane_width, 6.0), Color(1.0, 1.0, 1.0, 0.10))
	draw_circle(Vector2(lane_left, lane_y), 3.0, Color(1.0, 1.0, 1.0, 0.10))
	draw_circle(Vector2(lane_left + lane_width, lane_y), 3.0, Color(1.0, 1.0, 1.0, 0.10))
	
	var beat_span: float = lane_width / float(beats)
	var window_px: float = clampf(
			(float(_beat_manager.hit_window) / beat_length) * beat_span, 2.0, beat_span * 0.45)
	var strong_index: int = posmod(int(_beat_manager.strong_beat_index), beats)
	
	for i in beats:
		var tick_x: float = lane_left + (float(i) / float(beats)) * lane_width
		var strong: bool = i == strong_index
		var band_color: Color = strong_color if strong else accent_color
		if strong:
			band_color.a = 0.20 if on_beat else 0.10
		else:
			band_color.a = 0.16 if on_beat else 0.08
		draw_rect(Rect2(tick_x - window_px, lane_y - 20.0, window_px * 2.0, 40.0), band_color)
		if i == 0:
			# A bar loops, so the window around beat 0 also closes at the right edge.
			draw_rect(Rect2(lane_left + lane_width - window_px, lane_y - 20.0, window_px, 40.0), band_color)
		
		var tick_color: Color = strong_color if strong else Color(1.0, 1.0, 1.0, 0.35)
		tick_color.a = 0.90 if strong else 0.35
		draw_line(Vector2(tick_x, lane_y - 13.0), Vector2(tick_x, lane_y + 13.0), tick_color, 2.0, true)
	
	# Beat chips.
	var current_in_bar: int = posmod(int(floor(song_position / beat_length)), beats)
	var last_in_bar: int = posmod(_last_beat_index, beats)
	
	for i in beats:
		var tick_x: float = lane_left + (float(i) / float(beats)) * lane_width
		var strong: bool = i == strong_index
		var active: bool = i == current_in_bar
		var chip_color: Color = strong_color if strong else (accent_color if active else dim_color)
		var chip_radius: float = (13.0 if strong else 11.0) + (3.0 if i == last_in_bar else 0.0) * _flash
		
		draw_circle(Vector2(tick_x, chips_y), chip_radius, Color(0.02, 0.03, 0.05, 0.92))
		if active:
			draw_circle(Vector2(tick_x, chips_y), chip_radius, Color(chip_color, 0.22))
		draw_arc(Vector2(tick_x, chips_y), chip_radius, 0.0, TAU, 28, chip_color, 2.0, true)
		_draw_centered(str(i + 1), tick_x, chips_y + 4.0, 11, chip_color)
	
	# Playhead.
	draw_line(Vector2(playhead_x, lane_y - 24.0), Vector2(playhead_x, lane_y + 24.0),
			Color(tier_color, 0.22), 9.0, true)
	draw_line(Vector2(playhead_x, lane_y - 24.0), Vector2(playhead_x, lane_y + 24.0),
			Color(tier_color, 0.95), 2.5, true)
	draw_circle(Vector2(playhead_x, lane_y), 4.0, Color.WHITE if on_beat else tier_color)
	
	# JUMP badge.
	var badge_fill: Color = Color(tier_color, 0.30 + 0.15 * _flash) if on_beat else Color(tier_color, 0.10)
	draw_circle(badge_center, badge_radius, badge_fill)
	draw_arc(badge_center, badge_radius, 0.0, TAU, 48, Color(tier_color, 0.95 if on_beat else 0.45), 3.0, true)
	if _flash > 0.0:
		draw_arc(badge_center, badge_radius + (1.0 - _flash) * 14.0, 0.0, TAU, 48,
				Color(tier_color, _flash * 0.45), 2.0, true)
	_draw_centered("JUMP", badge_center.x, badge_center.y + 5.0, 15,
			Color.WHITE if on_beat else Color(0.78, 0.84, 0.92, 0.9))
	
	var tier_names: Array[String] = ["OFFBEAT", "ON BEAT", "STRONG"]
	_draw_centered(tier_names[clampi(tier, 0, 2)], badge_center.x, size.y - 8.0, 10,
			Color(tier_color, 0.95 if on_beat else 0.55))

func _draw_text(text: String, pos: Vector2, font_size: int, color: Color,
		alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, width: float = -1.0) -> void:
	draw_string(ThemeDB.fallback_font, pos, text, alignment, width, font_size, color)

func _draw_centered(text: String, center_x: float, baseline_y: float, font_size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, Vector2(center_x - 100.0, baseline_y), text,
			HORIZONTAL_ALIGNMENT_CENTER, 200.0, font_size, color)
