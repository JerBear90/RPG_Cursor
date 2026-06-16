extends PanelContainer

class_name VitalFrame

## Compact health or mana frame — icon, values, delayed damage bar, optional stamina + level.

signal value_updated(current: float, maximum: float)

@export var stat_kind: String = "health": # health | mana
	set(v):
		stat_kind = v
		if is_node_ready():
			_apply_kind()

var pending_current: float = 100.0
var pending_maximum: float = 100.0
var _widgets_ready: bool = false

var _icon: TextureRect
var _title: Label
var _values: Label
var _bar: ThinBar
var _damage_bar: ThinBar
var _stamina_bar: ThinBar
var _level_badge: PanelContainer
var _level_label: Label
var _flash: Panel

var _display: float = 100.0
var _damage_display: float = 100.0
var _target: float = 100.0
var _max: float = 100.0
var _stamina_display: float = 100.0
var _stamina_target: float = 100.0
var _stamina_max: float = 100.0
var _pulse: float = 0.0
var _value_tween: Tween
var _damage_tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_stylebox_override("panel", ArpgTheme.make_panel())
	custom_minimum_size = Vector2(UiMetrics.VITAL_FRAME_WIDTH, 0)
	_resolve_widgets()
	_widgets_ready = true
	_target = pending_current
	_max = pending_maximum
	_display = pending_current
	_damage_display = pending_current
	_apply_kind()
	if _flash:
		_flash.modulate = Color(1, 1, 1, 0)
		_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var flash_style := StyleBoxFlat.new()
		flash_style.bg_color = Color(0, 0, 0, 0)
		_flash.add_theme_stylebox_override("panel", flash_style)
	if _level_badge:
		_level_badge.add_theme_stylebox_override(
			"panel",
			ArpgTheme.make_panel(UiColors.PANEL_BG_DEEP, UiColors.BORDER_GOLD, UiMetrics.RADIUS_SM)
		)
	if _level_label:
		ArpgTheme.style_label(_level_label, UiMetrics.FONT_META, UiColors.TEXT_QUEST)
	_apply_values(false)


func set_level(level: int) -> void:
	if _level_label:
		_level_label.text = "LVL %d" % level


func set_values(current: float, maximum: float, animate: bool = true) -> void:
	pending_current = current
	pending_maximum = maxf(maximum, 1.0)
	if _widgets_ready:
		_apply_values(animate)


func get_display_text() -> String:
	if _values:
		return _values.text
	return "%d / %d" % [int(pending_current), int(pending_maximum)]


func get_primary_bar_value() -> float:
	return _bar.value if _bar else _display


func get_delayed_bar_value() -> float:
	return _damage_bar.value if _damage_bar else _damage_display


func set_stamina_values(current: float, maximum: float, animate: bool = true) -> void:
	if stat_kind != "health":
		return
	_resolve_widgets()
	if _stamina_bar == null:
		return
	_stamina_max = maxf(maximum, 1.0)
	_stamina_target = clampf(current, 0.0, _stamina_max)
	if not animate:
		_stamina_display = _stamina_target
		_apply_stamina()
	else:
		var tween := create_tween()
		tween.tween_method(_set_stamina_display, _stamina_display, _stamina_target, 0.18)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func flash_insufficient_resource() -> void:
	if stat_kind != "mana" or _flash == null:
		return
	var tween := create_tween()
	_flash.modulate = Color(UiColors.MANA_FLASH.r, UiColors.MANA_FLASH.g, UiColors.MANA_FLASH.b, 0.42)
	tween.tween_property(_flash, "modulate:a", 0.0, 0.32)


func _apply_values(animate: bool) -> void:
	var label_before := get_display_text()
	_resolve_widgets()
	var prev := _target
	_max = pending_maximum
	_target = clampf(pending_current, 0.0, _max)
	if _values:
		_values.text = "%d / %d" % [int(_target), int(_max)]
	if stat_kind == "health" and _target < prev:
		_flash_damage()
		if _damage_display < _target:
			_damage_display = _target
	if not animate:
		_display = _target
		if stat_kind == "health":
			_damage_display = _target
		_apply_bar_values()
	else:
		if _value_tween and _value_tween.is_valid():
			_value_tween.kill()
		_value_tween = create_tween()
		_value_tween.tween_method(_set_display, _display, _target, 0.22)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if stat_kind == "health" and _damage_display > _target:
			if _damage_tween and _damage_tween.is_valid():
				_damage_tween.kill()
			_damage_tween = create_tween()
			_damage_tween.tween_method(_set_damage_display, _damage_display, _target, 0.55)\
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	value_updated.emit(_target, _max)
	var _PlayerHealthDebug = preload("res://scripts/debug/player_health_debug.gd")
	_PlayerHealthDebug.log_hud_update(
		"VitalFrame applied",
		_target,
		_max,
		'label "%s" -> "%s"' % [label_before, get_display_text()]
	)


func _resolve_widgets() -> void:
	if _values == null:
		_values = get_node_or_null("%StatValues") as Label
	if _values == null:
		_values = get_node_or_null("Margin/HBox/VBox/HeaderRow/StatValues") as Label
	if _bar == null:
		_bar = get_node_or_null("%StatBar") as ThinBar
	if _bar == null:
		_bar = get_node_or_null("Margin/HBox/VBox/BarStack/StatBar") as ThinBar
	if _damage_bar == null:
		_damage_bar = get_node_or_null("%DamageBar") as ThinBar
	if _damage_bar == null:
		_damage_bar = get_node_or_null("Margin/HBox/VBox/BarStack/DamageBar") as ThinBar
	if _stamina_bar == null:
		_stamina_bar = get_node_or_null("%StaminaBar") as ThinBar
	if _stamina_bar == null:
		_stamina_bar = get_node_or_null("Margin/HBox/VBox/StaminaBar") as ThinBar
	if _icon == null:
		_icon = get_node_or_null("%StatIcon") as TextureRect
	if _icon == null:
		_icon = get_node_or_null("Margin/HBox/StatIcon") as TextureRect
	if _title == null:
		_title = get_node_or_null("%StatTitle") as Label
	if _title == null:
		_title = get_node_or_null("Margin/HBox/VBox/HeaderRow/StatTitle") as Label
	if _flash == null:
		_flash = get_node_or_null("%FlashOverlay") as Panel
	if _level_badge == null:
		_level_badge = get_node_or_null("%LevelBadge") as PanelContainer
	if _level_badge == null:
		_level_badge = get_node_or_null("Margin/HBox/VBox/HeaderRow/LevelBadge") as PanelContainer
	if _level_label == null:
		_level_label = get_node_or_null("%LevelLabel") as Label
	if _level_label == null:
		_level_label = get_node_or_null("Margin/HBox/VBox/HeaderRow/LevelBadge/LevelLabel") as Label


func _apply_kind() -> void:
	var is_health := stat_kind == "health"
	var icon_key := "health" if is_health else "mana"
	var fill := UiColors.HEALTH_FILL if is_health else UiColors.MANA_FILL
	if _icon:
		_icon.texture = UiIconRegistry.get_icon(icon_key)
		_icon.custom_minimum_size = Vector2(UiMetrics.ICON_VITAL, UiMetrics.ICON_VITAL)
		_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_icon.modulate = UiIconRegistry.get_tint(icon_key)
	if _title:
		_title.text = "HEALTH" if is_health else "MANA"
		ArpgTheme.style_label(_title, UiMetrics.FONT_META, UiColors.TEXT_MUTED)
	if _values:
		ArpgTheme.style_label(_values, UiMetrics.FONT_MD, UiColors.TEXT_PRIMARY)
	if _bar:
		_bar.set_bar_color(fill)
		_bar.set_bar_height(UiMetrics.BAR_HP if is_health else UiMetrics.BAR_MANA)
	if _damage_bar:
		_damage_bar.visible = is_health
		if is_health:
			_damage_bar.set_bar_color(UiColors.HEALTH_DAMAGE)
			_damage_bar.set_bar_height(UiMetrics.BAR_HP)
	if _stamina_bar:
		_stamina_bar.visible = is_health
		if is_health:
			_stamina_bar.set_bar_color(UiColors.STAMINA_FILL)
			_stamina_bar.set_bar_height(UiMetrics.BAR_STAMINA)
	if _level_badge:
		_level_badge.visible = is_health


func _set_display(v: float) -> void:
	_display = v
	_apply_bar_values()


func _set_damage_display(v: float) -> void:
	_damage_display = v
	if _damage_bar:
		_damage_bar.max_value = _max
		_damage_bar.value = _damage_display


func _set_stamina_display(v: float) -> void:
	_stamina_display = v
	_apply_stamina()


func _apply_bar_values() -> void:
	if _bar:
		_bar.max_value = _max
		_bar.value = _display
	if _damage_bar and stat_kind == "health":
		_damage_bar.max_value = _max
		_damage_bar.value = maxf(_damage_display, _display)


func _apply_stamina() -> void:
	if _stamina_bar:
		_stamina_bar.max_value = _stamina_max
		_stamina_bar.value = _stamina_display


func _flash_damage() -> void:
	if _flash == null:
		return
	var tween := create_tween()
	_flash.modulate = Color(UiColors.HEALTH_FLASH.r, UiColors.HEALTH_FLASH.g, UiColors.HEALTH_FLASH.b, 0.45)
	tween.tween_property(_flash, "modulate:a", 0.0, 0.28)


func _process(delta: float) -> void:
	if stat_kind != "health" or _max <= 0.0:
		modulate = Color.WHITE
		return
	var pct := _display / _max
	if pct <= 0.25 and pct > 0.0:
		_pulse += delta * 3.0
		var p := 0.88 + sin(_pulse) * 0.07
		modulate = Color(p, p * 0.93, p * 0.93, 1.0)
	else:
		modulate = Color.WHITE
		_pulse = 0.0
