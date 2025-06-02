@tool
extends EditorInspectorPlugin

var current_id_field: LineEdit
var current_gen_field: LineEdit
var current_scene_field: LineEdit
var current_button_container: HBoxContainer
var current_persistent_id: PersistentID

func _can_handle(object):
	return object is PersistentID

func _parse_begin(object):
	current_persistent_id = object as PersistentID
	
	var main_container = VBoxContainer.new()
	
	# Header
	var header = Label.new()
	header.text = "Persistent ID Manager"
	header.add_theme_font_size_override("font_size", 14)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_container.add_child(header)
	
	var separator = HSeparator.new()
	main_container.add_child(separator)
	
	# ID Field
	var id_label = Label.new()
	id_label.text = "ID:"
	id_label.add_theme_font_size_override("font_size", 11)
	id_label.modulate = Color.GRAY
	main_container.add_child(id_label)
	
	current_id_field = LineEdit.new()
	current_id_field.text = current_persistent_id.id if current_persistent_id.id != "" else "Not generated"
	current_id_field.editable = false
	current_id_field.selecting_enabled = true
	main_container.add_child(current_id_field)
	
	# Generated At Field
	var gen_label = Label.new()
	gen_label.text = "Generated:"
	gen_label.add_theme_font_size_override("font_size", 11)
	gen_label.modulate = Color.GRAY
	main_container.add_child(gen_label)
	
	current_gen_field = LineEdit.new()
	current_gen_field.text = current_persistent_id.generated_at if current_persistent_id.generated_at != "" else "Not generated"
	current_gen_field.editable = false
	current_gen_field.selecting_enabled = true
	main_container.add_child(current_gen_field)
	
	# Scene Path Field
	var scene_label = Label.new()
	scene_label.text = "Scene:"
	scene_label.add_theme_font_size_override("font_size", 11)
	scene_label.modulate = Color.GRAY
	main_container.add_child(scene_label)
	
	current_scene_field = LineEdit.new()
	current_scene_field.text = current_persistent_id.scene_path if current_persistent_id.scene_path != "" else "Unknown"
	current_scene_field.editable = false
	current_scene_field.selecting_enabled = true
	main_container.add_child(current_scene_field)
	
	# Buttons
	current_button_container = HBoxContainer.new()
	_create_buttons()
	main_container.add_child(current_button_container)
	
	# Warning for regeneration
	if not current_persistent_id.id.is_empty():
		var warning = Label.new()
		warning.text = "Warning: Regenerating will remove the current ID from the registry"
		warning.add_theme_font_size_override("font_size", 9)
		warning.modulate = Color.ORANGE
		warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		main_container.add_child(warning)
	
	add_custom_control(main_container)

func _create_buttons():
	# Clear existing buttons
	for child in current_button_container.get_children():
		child.queue_free()
	
	var generate_btn = Button.new()
	if current_persistent_id.id.is_empty():
		generate_btn.text = "Generate ID"
		generate_btn.modulate = Color.GREEN
	else:
		generate_btn.text = "Regenerate ID"
		generate_btn.modulate = Color.ORANGE
	
	generate_btn.pressed.connect(_on_generate_pressed)
	current_button_container.add_child(generate_btn)
	
	# Copy button if ID exists
	if not current_persistent_id.id.is_empty():
		var copy_btn = Button.new()
		copy_btn.text = "Copy ID"
		copy_btn.pressed.connect(_on_copy_pressed)
		current_button_container.add_child(copy_btn)

func _on_generate_pressed():
	if current_persistent_id.id.is_empty():
		current_persistent_id.generate_id()
	else:
		current_persistent_id.force_generate_id()
	
	_update_all_fields()

func _update_all_fields():
	if current_id_field:
		current_id_field.text = current_persistent_id.id if current_persistent_id.id != "" else "Not generated"
	
	if current_gen_field:
		current_gen_field.text = current_persistent_id.generated_at if current_persistent_id.generated_at != "" else "Not generated"
	
	if current_scene_field:
		current_scene_field.text = current_persistent_id.scene_path if current_persistent_id.scene_path != "" else "Unknown"
	
	_create_buttons()

func _on_copy_pressed():
	DisplayServer.clipboard_set(current_persistent_id.id)
