extends Control
class_name NotificationToast
## Compact toast queue — icon, title, optional body, reward line, timer bar.

const MIN_WIDTH := 364.0
const MAX_WIDTH := 406.0
const SLIDE_OFFSET := 8.0

@onready var _panel: PanelContainer = %ToastPanel
@onready var _icon: TextureRect = %ToastIcon
@onready var _title: Label = %ToastTitle
@onready var _body: Label = %ToastBody
@onready var _reward: Label = %ToastReward
@onready var _timer_bar: ThinBar = %ToastTimer

var _queue: Array[Dictionary] = []
var _active: bool = false
var _time_left: float = 0.0

enum Priority { CRITICAL = 0, IMPORTANT = 1, NORMAL = 2 }


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(MIN_WIDTH, 0)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if _panel:
		_panel.add_theme_stylebox_override("panel", ArpgTheme.make_panel())
		_panel.custom_minimum_size = Vector2(MIN_WIDTH, 0)
		_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	if _reward:
		ArpgTheme.style_label(_reward, UiMetrics.FONT_SM, UiColors.TEXT_CURRENCY)
		_reward.autowrap_mode = TextServer.AUTOWRAP_OFF
	if _timer_bar:
		_timer_bar.set_bar_color(UiColors.TEXT_QUEST)
		_timer_bar.set_bar_height(3.0)
	visible = false
	modulate.a = 0.0
	position.y = 0.0


static func format_reward_text(summary: String) -> String:
	var raw := summary.strip_edges()
	if raw.is_empty():
		return ""
	for suffix in [" copper, ", " silver, "]:
		var idx := raw.find(suffix)
		if idx >= 0:
			var coin_len := len(" copper") if suffix.begins_with(" copper") else len(" silver")
			var currency_part := raw.substr(0, idx + coin_len)
			var extras := raw.substr(idx + len(suffix)).strip_edges()
			if extras.is_empty():
				return "(%s)" % currency_part
			return "(%s)\n%s" % [currency_part, extras]
	if raw.ends_with(" copper") or raw.ends_with(" silver"):
		return "(%s)" % raw
	if raw.begins_with("+"):
		return "(%s)" % raw
	return raw


func show_message(
	text: String,
	duration: float = 3.0,
	description: String = "",
	icon_key: String = "notification",
	reward: String = "",
	priority: int = Priority.NORMAL
) -> void:
	var item := {
		"title": text,
		"body": description,
		"reward": reward,
		"duration": duration,
		"icon": icon_key,
		"priority": priority,
	}
	_insert_queue_item(item)
	if not _active:
		_show_next()


func _insert_queue_item(item: Dictionary) -> void:
	var priority: int = int(item.get("priority", Priority.NORMAL))
	if priority == Priority.CRITICAL:
		_queue.insert(0, item)
		return
	if priority == Priority.IMPORTANT:
		var idx := 0
		while idx < _queue.size() and int(_queue[idx].get("priority", Priority.NORMAL)) == Priority.CRITICAL:
			idx += 1
		_queue.insert(idx, item)
		return
	_queue.append(item)


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
	if _reward:
		var reward_raw := str(item.get("reward", ""))
		var reward_text := format_reward_text(reward_raw)
		_reward.text = reward_text
		_reward.visible = reward_text != ""
	if _icon:
		var key := str(item.get("icon", "notification"))
		_icon.texture = UiIconRegistry.get_icon(key if UiIconRegistry.path_for(key) != "" else "notification")
	_time_left = float(item.get("duration", 3.0))
	if _timer_bar:
		_timer_bar.max_value = _time_left
		_timer_bar.value = _time_left
	custom_minimum_size.x = MIN_WIDTH
	if _panel:
		_panel.custom_minimum_size.x = MIN_WIDTH
	var text_w := MIN_WIDTH - 88.0
	if _title:
		_title.custom_minimum_size.x = text_w
	if _body:
		_body.custom_minimum_size.x = text_w
	if _reward:
		_reward.custom_minimum_size.x = text_w
	visible = true
	position.y = SLIDE_OFFSET
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
	tween.tween_property(self, "position:y", SLIDE_OFFSET * 0.5, 0.22)
	tween.chain().tween_callback(func():
		visible = false
		position.y = 0.0
		_show_next()
	)
