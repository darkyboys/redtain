@tool
extends Control

const CONFIG = preload("res://addons/ambientcg/core/ambient_config.gd")

const SETTINGS_MAP = {
	CONFIG.SETTING_MATERIAL_DIR: [CONFIG.DEFAULT_MATERIAL_DIR],
	CONFIG.SETTING_EXTRACT_PATH: [CONFIG.DEFAULT_EXTRACT_PATH],
	CONFIG.SETTING_ENVIRONMENT_DIR: [CONFIG.DEFAULT_ENVIRONMENT_DIR],
	CONFIG.SETTING_DOWNLOAD_PATH: [CONFIG.DEFAULT_DOWNLOAD_PATH]
}

@onready var mat_path_edit: LineEdit = %MatPath
@onready var ext_path_edit: LineEdit = %ExtPath
@onready var env_path_edit: LineEdit = %EnvPath
@onready var down_path_edit: LineEdit = %DownPath
@onready var ask_before_download: CheckBox = %AskBeforeDownload
@onready var save_button: Button = %SaveButton


func _ready() -> void:
	load_settings()
	save_button.pressed.connect(_on_save_button_pressed)


func load_settings():
	mat_path_edit.text = CONFIG.get_setting(
		CONFIG.SETTING_MATERIAL_DIR, CONFIG.DEFAULT_MATERIAL_DIR
	)
	ext_path_edit.text = CONFIG.get_setting(
		CONFIG.SETTING_EXTRACT_PATH, CONFIG.DEFAULT_EXTRACT_PATH
	)
	env_path_edit.text = CONFIG.get_setting(
		CONFIG.SETTING_ENVIRONMENT_DIR, CONFIG.DEFAULT_ENVIRONMENT_DIR
	)
	down_path_edit.text = CONFIG.get_setting(
		CONFIG.SETTING_DOWNLOAD_PATH, CONFIG.DEFAULT_DOWNLOAD_PATH
	)
	ask_before_download.button_pressed = CONFIG.get_setting(
		CONFIG.SETTING_ASK_BEFORE_DOWNLOAD, true
	)


func _on_save_button_pressed() -> void:
	CONFIG.set_setting(CONFIG.SETTING_MATERIAL_DIR, mat_path_edit.text)
	CONFIG.set_setting(CONFIG.SETTING_EXTRACT_PATH, ext_path_edit.text)
	CONFIG.set_setting(CONFIG.SETTING_ENVIRONMENT_DIR, env_path_edit.text)
	CONFIG.set_setting(CONFIG.SETTING_DOWNLOAD_PATH, down_path_edit.text)
	CONFIG.set_setting(CONFIG.SETTING_ASK_BEFORE_DOWNLOAD, ask_before_download.button_pressed)

	var ambient_cg = CONFIG.get_instance(self)
	if ambient_cg:
		ambient_cg.logger.info("Settings saved successfully", "Settings")

	load_settings()
