extends Control
class_name NotificationToast
## Compact toast queue — icon, title, optional body, timer bar.

const MAX_WIDTH := 420.0

@onready var _panel: PanelContainer = %ToastPanel
@onready var _icon: TextureRect = %ToastIcon
@onready var _title: Label = %ToastTitle
@onready var _body: Label = %ToastBody
@onready var _timer_bar: ThinBar = %ToastTimer

var _queue: Array[Dictionary] = []
var _active: bool = false
var _time_left: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(280, 0)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if _panel:
		_panel.add_theme_stylebox_override("panel", ArpgTheme.make_panel())
		_panel.custom_minimum_size.x = 0.0
	var icon_box := get_node_or_null("ToastPanel/Margin/VBox/HBox/IconContainer") as PanelContainer
	if icon_box:
		icon_box.add_theme_stylebox_override("panel", ArpgTheme.make_inset_panel())
	if _icon:
		_icon.texture = UiIconRegistry.get_icon("notification")
		_icon.custom_minimum_size = Vector2(UiMetrics.ICON_TOAST, UiMetrics.ICON_TOAST)
		_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ArpgTheme.style_label(_title, UiMetrics.FONT_MD, UiColors.TEXT_PRIMARY)
	ArpgTheme.style_label(_body, UiMetrics.FONT_SM, UiColors.TEXT_SECONDARY)
	if _timer_bar:
		_timer_bar.set_bar_color(UiColors.TEXT_QUEST)
		_timer_bar.set_bar_height(3.0)
	visible = false
	modulate.a = 0.0
	position.y = -12.0


func show_message(text: String, duration: float = 3.0, description: String = "", icon_key: String = "notification") -> void:
	_queue.append({"title": text, "body": description, "duration": duration, "icon": icon_key})
	if not _active:
		_show_next()


func _show_next() -> void:
	if _queue.is_empty():
		_active = false
		return
	_active = true
	var item: Dictionary = _queue.pop_front()
	if _title:
		_title.text = str(item.get("title", ""))
	if _body:
		var body := str(item.get("body", ""))
		_body.text = body
		_body.visible = body != ""
	if _icon:
		var key := str(item.get("icon", "notification"))
		_icon.texture = UiIconRegistry.get_icon(key if UiIconRegistry.path_for(key) != "" else "notification")
	_time_left = float(item.get("duration", 3.0))
	if _timer_bar:
		_timer_bar.max_value = _time_left
		_timer_bar.value = _time_left
	visible = true
	position.y = -12.0
	modulate.a = 0.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.18)
	tween.tween_property(self, "position:y", 0.0, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	if not _active or not visible:
		return
	_time_left -= delta
	if _timer_bar:
		_timer_bar.value = maxf(_time_left, 0.0)
	if _time_left <= 0.0:
		_dismiss()


func _dismiss() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.22)
	tween.tween_property(self, "position:y", -10.0, 0.22)
	tween.chain().tween_callback(func():
		visible = false
		_show_next()
	)
