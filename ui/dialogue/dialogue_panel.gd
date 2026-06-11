extends Control
class_name DialoguePanel
## Bottom-center dialogue panel — contained layout above ability bar.

@onready var _speaker: Label = %SpeakerName
@onready var _divider: ColorRect = %Divider
@onready var _body: Label = %DialogueText
@onready var _choices: VBoxContainer = %ChoicesContainer
@onready var _continue: Label = %ContinueHint
@onready var _leave: Label = %LeaveHint


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_apply_theme()


func _apply_theme() -> void:
	var panel := get_node_or_null("DialogueSafeArea/CenterAnchor/DialoguePanel") as PanelContainer
	if panel:
		panel.add_theme_stylebox_override("panel", ArpgTheme.make_panel(UiColors.PANEL_BG_DEEP, UiColors.BORDER_BRONZE, UiMetrics.RADIUS_MD))
		panel.custom_minimum_size.x = 560.0
		panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	get_viewport().size_changed.connect(_clamp_panel_width)
	call_deferred("_clamp_panel_width")
	if _speaker:
		ArpgTheme.style_label(_speaker, UiMetrics.FONT_LG, UiColors.TEXT_PRIMARY)
	if _body:
		ArpgTheme.style_label(_body, UiMetrics.FONT_MD, UiColors.TEXT_PRIMARY)
		_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if _continue:
		ArpgTheme.style_label(_continue, UiMetrics.FONT_SM, UiColors.TEXT_QUEST)
	if _leave:
		ArpgTheme.style_label(_leave, UiMetrics.FONT_META, UiColors.TEXT_SECONDARY)


func show_line(speaker: String, text: String, show_continue: bool = true, show_leave: bool = true) -> void:
	visible = true
	if _speaker:
		_speaker.text = speaker
	if _body:
		_body.text = text
	if _choices:
		for c in _choices.get_children():
			c.queue_free()
		_choices.visible = false
	if _continue:
		_continue.visible = show_continue
		_continue.text = "[E] Continue"
	if _leave:
		_leave.visible = show_leave
		_leave.text = "[Esc] Leave"


func show_choices(options: Array[String]) -> void:
	visible = true
	if _choices == null:
		return
	for c in _choices.get_children():
		c.queue_free()
	_choices.visible = options.size() > 0
	for i in options.size():
		var lbl := Label.new()
		var key := "Enter" if i == 0 else "Esc"
		ArpgTheme.style_label(lbl, UiMetrics.FONT_SM, UiColors.TEXT_QUEST if i == 0 else UiColors.TEXT_PRIMARY)
		lbl.text = "[%s] %s" % [key, options[i]]
		_choices.add_child(lbl)
	if _continue:
		_continue.visible = false
	if _leave:
		_leave.visible = options.size() > 1
		if options.size() > 1:
			_leave.text = "[Esc] %s" % options[1]


func hide_panel() -> void:
	visible = false


func _clamp_panel_width() -> void:
	var panel := get_node_or_null("DialogueSafeArea/CenterAnchor/DialoguePanel") as PanelContainer
	if panel == null:
		return
	var viewport_w := get_viewport().get_visible_rect().size.x
	var target_w := clampf(viewport_w * 0.47, 560.0, 900.0)
	panel.custom_minimum_size.x = target_w
