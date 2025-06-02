@tool
extends EditorPlugin

const addon_path := "res://addons/Persistent-ID-Plugin/"

const pid := preload(addon_path + "persistent_id.gd")
const inspector := preload(addon_path + "persistent_id_inspector.gd")
const dock := preload(addon_path + "id_manager_dock.gd")
const icon := preload(addon_path + "icon.svg")

var dock_instance
var inspector_plugin

func _enter_tree():
	
	# Add custom type with icon
	add_custom_type(
		"PersistentID",
		"Resource", 
		pid,
		icon
	)
	
	# Add custom inspector
	inspector_plugin = inspector.new()
	if inspector_plugin:
		add_inspector_plugin(inspector_plugin)
	
	# Create dock
	dock_instance = dock.new()
	if dock_instance:
		dock_instance.name = "PersistentIDDock"
		add_control_to_dock(DOCK_SLOT_LEFT_UL, dock_instance)
	
	print("PersistentID Plugin activated successfully!")

func _exit_tree():
	
	# Note: No need to save registry on exit since we don't use cache anymore
	# Registry is saved immediately on each operation
	
	remove_custom_type("PersistentID")
	
	if inspector_plugin:
		remove_inspector_plugin(inspector_plugin)
		inspector_plugin = null
	
	if dock_instance:
		remove_control_from_docks(dock_instance)
		dock_instance.queue_free()
		dock_instance = null
	
	print("PersistentID Plugin deactivated")
