@tool
extends Control

var tree: Tree
var search_field: LineEdit
var all_items: Array = []
var status_label: Label

func _ready():
	name = "PersistentIDManager"
	set_custom_minimum_size(Vector2(300, 250))
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	_setup_ui()
	call_deferred("_refresh_tree")

func _setup_ui():
	# Clear existing children
	for child in get_children():
		child.queue_free()
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "Persistent ID Manager"
	title.add_theme_font_size_override("font_size", 12)
	vbox.add_child(title)
	
	# Status
	status_label = Label.new()
	status_label.text = "Ready"
	status_label.modulate = Color.GRAY
	status_label.add_theme_font_size_override("font_size", 10)
	vbox.add_child(status_label)
	
	# Search
	search_field = LineEdit.new()
	search_field.placeholder_text = "Search IDs..."
	search_field.text_changed.connect(_on_search_changed)
	search_field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(search_field)
	
	# Tree
	tree = Tree.new()
	tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tree.columns = 1
	tree.hide_root = false
	tree.custom_minimum_size = Vector2(250, 150)
	vbox.add_child(tree)
	
	# Buttons
	var btn_container = VBoxContainer.new()
	
	var refresh_btn = Button.new()
	refresh_btn.text = "Refresh"
	refresh_btn.pressed.connect(_refresh_tree)
	refresh_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var export_btn = Button.new()
	export_btn.text = "Export Registry"
	export_btn.pressed.connect(_export_registry)
	export_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var delete_btn = Button.new()
	delete_btn.text = "Delete Registry"
	delete_btn.pressed.connect(_show_delete_confirmation)
	delete_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	delete_btn.modulate = Color(1.0, 0.8, 0.8)  # Light red tint
	
	btn_container.add_child(refresh_btn)
	btn_container.add_child(export_btn)
	btn_container.add_child(delete_btn)
	vbox.add_child(btn_container)

func _refresh_tree():
	if not tree:
		return
	
	tree.clear()
	all_items.clear()
	
	var root = tree.create_item()
	root.set_text(0, "Persistent IDs")
	
	var registry = PersistentID.get_registry_data()
	
	if registry.is_empty():
		var no_ids_item = tree.create_item(root)
		no_ids_item.set_text(0, "No IDs found - Generate some first!")
		no_ids_item.set_custom_color(0, Color.GRAY)
		all_items.append({"item": no_ids_item, "text": "No IDs found - Generate some first!"})
		_update_status("No IDs in registry")
	else:
		for id in registry.keys():
			var data = registry[id]
			var item = tree.create_item(root)
			item.set_text(0, id)
			
			var scene_path = data.get("scene_path", "unknown")
			var generated_at = data.get("generated_at", "unknown")
			var tooltip = "ID: " + id + "\nGenerated: " + generated_at + "\nScene: " + scene_path
			item.set_tooltip_text(0, tooltip)
			
			all_items.append({"item": item, "text": id, "data": data})
		
		_update_status(str(registry.size()) + " IDs in registry")
	
	root.set_collapsed(false)

func _update_status(message: String, color: Color = Color.GRAY):
	if status_label:
		status_label.text = message
		status_label.modulate = color

func _export_registry():
	var registry = PersistentID.get_registry_data()
	
	var export_data = {
		"exported_at": Time.get_datetime_string_from_system(),
		"total_ids": registry.size(),
		"ids": registry
	}
	
	var export_path = "user://persistent_id_export_" + str(Time.get_unix_time_from_system()) + ".json"
	var file = FileAccess.open(export_path, FileAccess.WRITE)
	
	if file:
		file.store_string(JSON.stringify(export_data, "\t"))
		file.close()
		_update_status("Registry exported successfully", Color.GREEN)
		
		# Reset status after 3 seconds
		var timer = get_tree().create_timer(3.0)
		timer.timeout.connect(func(): _update_status("Ready"))
	else:
		_update_status("Failed to export registry", Color.RED)

func _show_delete_confirmation():
	var registry = PersistentID.get_registry_data()
	var id_count = registry.size()
	
	if id_count == 0:
		_update_status("No registry to delete", Color.GRAY)
		return
	
	# Create confirmation dialog
	var confirmation = ConfirmationDialog.new()
	confirmation.title = "Delete Registry"
	confirmation.dialog_text = "Are you sure you want to delete the entire registry?\n\nThis will remove " + str(id_count) + " persistent ID(s) permanently.\n\nThis action cannot be undone."
	confirmation.ok_button_text = "Delete"
	confirmation.cancel_button_text = "Cancel"
	
	# Style the OK button to look dangerous
	confirmation.confirmed.connect(_delete_registry)
	confirmation.canceled.connect(func(): _update_status("Delete cancelled", Color.GRAY))
	
	# Add to scene and show
	add_child(confirmation)
	confirmation.popup_centered()
	
	# Clean up dialog after use
	confirmation.tree_exited.connect(confirmation.queue_free)

func _delete_registry():
	_update_status("Deleting registry...", Color.ORANGE)
	PersistentID.delete_registry()
	_update_status("Registry deleted", Color.GREEN)
	call_deferred("_refresh_tree")
	
	# Reset status after 3 seconds
	var timer = get_tree().create_timer(3.0)
	timer.timeout.connect(func(): _update_status("Ready"))

func _on_search_changed(text: String):
	if not tree:
		return
		
	if text.is_empty():
		_refresh_tree()
		return
	
	tree.clear()
	var root = tree.create_item()
	root.set_text(0, "Persistent IDs (Filtered)")
	
	var search_lower = text.to_lower()
	var found_items = 0
	
	for item_data in all_items:
		var item_text = item_data.text.to_lower()
		if search_lower in item_text:
			var new_item = tree.create_item(root)
			new_item.set_text(0, item_data.text)
			
			if item_data.has("data"):
				var data = item_data.data
				var scene_path = data.get("scene_path", "unknown")
				var generated_at = data.get("generated_at", "unknown")
				var tooltip = "ID: " + item_data.text + "\nGenerated: " + generated_at + "\nScene: " + scene_path
				new_item.set_tooltip_text(0, tooltip)
			
			found_items += 1
	
	if found_items == 0:
		var no_match_item = tree.create_item(root)
		no_match_item.set_text(0, "No matching IDs found")
		no_match_item.set_custom_color(0, Color.GRAY)
	
	root.set_collapsed(false)
	_update_status("Showing " + str(found_items) + " matching IDs")