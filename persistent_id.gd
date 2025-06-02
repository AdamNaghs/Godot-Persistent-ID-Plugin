@tool
extends Resource
class_name PersistentID

# Simple properties
var id: String = "":
	set(value):
		if value != "" and id == "":
			print("PersistentID: ID loaded from file: ", value)
			_was_loaded_from_file = true
		id = value
		emit_changed()
		if value != "" and _was_loaded_from_file:
			call_deferred("_ensure_id_in_registry")

var generated_at: String = "":
	set(value):
		generated_at = value
		emit_changed()

var scene_path: String = "":
	set(value):
		scene_path = value
		emit_changed()

# Registry path - simple and direct
const REGISTRY_PATH = "res://addons/Persistent-ID-Plugin/id_registry.json"

# Prevent double generation
var _generation_in_progress: bool = false
var _was_loaded_from_file: bool = false

func _init():
	if Engine.is_editor_hint():
		print("PersistentID: Resource initialized")

func _ensure_id_in_registry():
	"""Ensure this ID exists in the registry"""
	if id == "":
		return
		
	var registry = _load_registry()
	
	if not registry.has(id):
		print("PersistentID: Adding ID to registry: ", id)
		registry[id] = {
			"generated_at": generated_at if generated_at != "" else Time.get_datetime_string_from_system(),
			"scene_path": scene_path if scene_path != "" else "unknown"
		}
		_save_registry(registry)

func generate_id():
	"""Generate a new ID"""
	
	# Don't regenerate if loaded from file
	if not id.is_empty() and _was_loaded_from_file:
		print("PersistentID: Skipping - ID loaded from file: ", id)
		return
	
	if _generation_in_progress or not id.is_empty():
		return
	
	_generation_in_progress = true
	print("PersistentID: Generating new ID...")
	
	var registry = _load_registry()
	
	# Generate unique ID
	var timestamp = Time.get_unix_time_from_system()
	var random_part = randi() % 999999
	var new_id = "pid_" + str(timestamp) + "_" + str(random_part).pad_zeros(6)
	
	while registry.has(new_id):
		random_part = randi() % 999999
		new_id = "pid_" + str(timestamp) + "_" + str(random_part).pad_zeros(6)
	
	# Set properties
	id = new_id
	generated_at = Time.get_datetime_string_from_system()
	scene_path = "unknown"
	
	# Get scene context
	if Engine.is_editor_hint() and EditorInterface:
		var edited_scene = EditorInterface.get_edited_scene_root()
		if edited_scene and edited_scene.scene_file_path:
			scene_path = edited_scene.scene_file_path
	
	# Save to registry
	registry[id] = {
		"generated_at": generated_at,
		"scene_path": scene_path
	}
	_save_registry(registry)
	
	_generation_in_progress = false
	print("PersistentID: Generated ID: ", id)

func force_generate_id():
	"""Force regenerate ID"""
	print("PersistentID: Force regenerating ID")
	
	_generation_in_progress = false
	_was_loaded_from_file = false
	
	# Remove old ID from registry
	var old_id = id
	if old_id != "":
		var registry = _load_registry()
		registry.erase(old_id)
		_save_registry(registry)
	
	# Clear and regenerate
	id = ""
	generated_at = ""
	scene_path = ""
	generate_id()

static func _load_registry() -> Dictionary:
	"""Load registry from file"""
	var registry = {}
	
	if FileAccess.file_exists(REGISTRY_PATH):
		var file = FileAccess.open(REGISTRY_PATH, FileAccess.READ)
		if file:
			var json = JSON.new()
			if json.parse(file.get_as_text()) == OK and json.data is Dictionary:
				registry = json.data
			file.close()
	
	return registry

static func _save_registry(registry: Dictionary):
	"""Save registry to file"""
	var dir = DirAccess.open("res://")
	if dir:
		dir.make_dir_recursive("addons/Persistent-ID-Plugin")
	
	var file = FileAccess.open(REGISTRY_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(registry, "\t"))
		file.close()
		print("PersistentID: Registry saved with ", registry.size(), " IDs")

static func delete_registry():
	"""Delete the registry file"""
	if FileAccess.file_exists(REGISTRY_PATH):
		DirAccess.open("res://").remove(REGISTRY_PATH)
		print("PersistentID: Registry deleted")

static func create_new() -> PersistentID:
	"""Create new PersistentID with auto-generated ID"""
	var new_pid = PersistentID.new()
	new_pid.generate_id()
	return new_pid

static func get_all_ids() -> Array[String]:
	"""Get all IDs from registry"""
	var registry = _load_registry()
	var ids: Array[String] = []
	for key in registry.keys():
		ids.append(key)
	return ids

static func get_registry_data() -> Dictionary:
	"""Get full registry data"""
	return _load_registry()

static func remove_id_from_registry(id_to_remove: String) -> bool:
	"""Remove specific ID from registry"""
	var registry = _load_registry()
	if registry.has(id_to_remove):
		registry.erase(id_to_remove)
		_save_registry(registry)
		return true
	return false

func _get_property_list():
	return [
		{"name": "id", "type": TYPE_STRING, "usage": PROPERTY_USAGE_STORAGE},
		{"name": "generated_at", "type": TYPE_STRING, "usage": PROPERTY_USAGE_STORAGE},
		{"name": "scene_path", "type": TYPE_STRING, "usage": PROPERTY_USAGE_STORAGE}
	]
