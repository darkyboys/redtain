@tool
extends EditorPlugin

const AMBIENT_UI_SCENE = preload("res://addons/ambientcg/ui/main/ambient_ui.tscn")
const MAIN_AUTOLOAD_NAME = "AmbientCG"
const MAIN_AUTOLOAD_PATH = "res://addons/ambientcg/ambient_cg.gd"

var main_panel_instance


func _enter_tree() -> void:
	add_autoload_singleton(MAIN_AUTOLOAD_NAME, MAIN_AUTOLOAD_PATH)

	main_panel_instance = AMBIENT_UI_SCENE.instantiate()
	EditorInterface.get_editor_main_screen().add_child(main_panel_instance)
	_make_visible(false)


func _exit_tree() -> void:
	if main_panel_instance:
		main_panel_instance.queue_free()

	remove_autoload_singleton(MAIN_AUTOLOAD_NAME)


func _has_main_screen() -> bool:
	return true


func _make_visible(visible: bool) -> void:
	if main_panel_instance:
		main_panel_instance.visible = visible


func _get_plugin_name() -> String:
	return "AmbientCG"


func _get_plugin_icon() -> Texture2D:
	return EditorInterface.get_editor_theme().get_icon("ResourcePreloader", "EditorIcons")
