extends Control
class_name ResourceGainToast
## Stacked resource gain rows — right-center, non-overlapping mana.

const MAX_ROWS := 5
const ROW_LIFETIME := 2.5
const COMBINE_WINDOW := 0.8

var _stack: VBoxContainer
var _rows: Array[Dictionary] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stack = VBoxContainer.new()
	_stack.name = "ResourceGainStack"
	_stack.set_anchors_preset(Control.PRESET_FULL_RECT)
	_stack.alignment = BoxContainer.ALIGNMENT_END
	add_child(_stack)
	set_process(true)


func show_rewards(rewards: Dictionary) -> void:
	for item_id in rewards.keys():
		var amount: int = int(rewards[item_id])
		if amount <= 0:
			continue
		_combine_or_add(str(item_id), amount)
	_trim_rows()


func _combine_or_add(item_id: String, amount: int) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	for entry in _rows:
		if entry.id == item_id and now - float(entry.time) <= COMBINE_WINDOW:
			entry.amount += amount
			entry.time = now
			entry.label.text = _format_row(item_id, entry.amount)
			return
	var lbl := Label.new()
	ArpgTheme.style_label(lbl, UiMetrics.FONT_SM, UiColors.TEXT_CURRENCY)
	lbl.text = _format_row(item_id, amount)
	_stack.add_child(lbl)
	_rows.append({"id": item_id, "amount": amount, "time": now, "label": lbl})


func _format_row(item_id: String, amount: int) -> String:
	var name := item_id.replace("_", " ").capitalize()
	return "+%d %s" % [amount, name]


func _trim_rows() -> void:
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
