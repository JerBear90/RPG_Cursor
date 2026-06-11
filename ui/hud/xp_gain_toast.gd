extends Control
class_name XpGainToast
## Compact combat XP feedback near the XP bar.

const ROW_LIFETIME := 1.75
const COMBINE_WINDOW := 0.35
const MAX_ROWS := 4

var _stack: VBoxContainer
var _rows: Array[Dictionary] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stack = VBoxContainer.new()
	_stack.set_anchors_preset(Control.PRESET_FULL_RECT)
	_stack.alignment = BoxContainer.ALIGNMENT_END
	add_child(_stack)
	set_process(true)


func show_xp(amount: int, label: String, is_kill: bool) -> void:
	if amount <= 0:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if not is_kill:
		for entry in _rows:
			if not entry.get("is_kill", false) and now - float(entry.time) <= COMBINE_WINDOW:
				entry.amount += amount
				entry.time = now
				entry.label.text = "+%d XP" % entry.amount
				return
	var lbl := Label.new()
	var color := UiColors.TEXT_CURRENCY if is_kill else UiColors.TEXT_QUEST
	ArpgTheme.style_label(lbl, UiMetrics.FONT_SM, color)
	lbl.text = label
	_stack.add_child(lbl)
	_rows.append({"amount": amount, "time": now, "label": lbl, "is_kill": is_kill})
	while _rows.size() > MAX_ROWS:
		var old: Dictionary = _rows.pop_front()
		if old.label and is_instance_valid(old.label):
			old.label.queue_free()


func _process(_delta: float) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	var i := 0
	while i < _rows.size():
		var entry: Dictionary = _rows[i]
		if now - float(entry.time) >= ROW_LIFETIME:
			if entry.label and is_instance_valid(entry.label):
				entry.label.queue_free()
			_rows.remove_at(i)
		else:
			i += 1
