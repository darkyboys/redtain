@tool

const SETTING_DOWNLOAD_PATH = "ambientcg/download_path"
const SETTING_EXTRACT_PATH = "ambientcg/extract_path"
const SETTING_MATERIAL_DIR = "ambientcg/material_file_directory"
const SETTING_ENVIRONMENT_DIR = "ambientcg/environment_file_directory"
const SETTING_ASK_BEFORE_DOWNLOAD = "ambientcg/ask_before_download"

const DEFAULT_DOWNLOAD_PATH = "res://ambientcg/temp"
const DEFAULT_EXTRACT_PATH = "res://ambientcg/extracted"
const DEFAULT_MATERIAL_DIR = "res://ambientcg/materials"
const DEFAULT_ENVIRONMENT_DIR = "res://ambientcg/environments"

const HOME_URL = "https://ambientcg.com/api/v3/"
const BASE_DOMAIN = "https://ambientcg.com"

const THEME_PATH = "res://addons/ambientcg/resources/themes/ambient_theme.tres"
const ICON_PATH = "res://addons/ambientcg/resources/icons/"

static var _cached_cfg: ConfigFile = null


static func get_setting(key: String, default_value: Variant) -> Variant:
	return ProjectSettings.get_setting(key, default_value)


static func get_instance(node: Node) -> Node:
	if node.is_inside_tree():
		return node.get_node_or_null("/root/AmbientCG")
	return null


static func is_plugin_enabled() -> bool:
	return ProjectSettings.has_setting("autoload/AmbientCG")


static func set_setting(key: String, value: Variant) -> void:
	if (
		key
		in [
			SETTING_DOWNLOAD_PATH,
			SETTING_EXTRACT_PATH,
			SETTING_MATERIAL_DIR,
			SETTING_ENVIRONMENT_DIR,
			SETTING_ASK_BEFORE_DOWNLOAD
		]
	):
		if typeof(value) == TYPE_STRING:
			value = value.to_lower()
	ProjectSettings.set_setting(key, value)
	ProjectSettings.save()


static func _get_plugin_cfg() -> ConfigFile:
	if _cached_cfg:
		return _cached_cfg
	var config = ConfigFile.new()
	var err = config.load("res://addons/ambientcg/plugin.cfg")
	if err == OK:
		_cached_cfg = config
		return _cached_cfg
	return null


static func get_plugin_version() -> String:
	var cfg = _get_plugin_cfg()
	return cfg.get_value("plugin", "version", "0.0.0") if cfg else "0.0.0"


static func get_plugin_name() -> String:
	var cfg = _get_plugin_cfg()
	return cfg.get_value("plugin", "name", "AmbientCG") if cfg else "AmbientCG"
