@tool
extends PanelContainer

const CONFIG = preload("res://addons/ambientcg/core/ambient_config.gd")

var url: String = ""
var asset_name: String = ""
var local_path: String = ""
var _is_extracting: bool = false

@onready var title_label: Label = %Title
@onready var status_label: Label = %Status
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var extract_button: Button = %ExtractButton


func _ready() -> void:
	title_label.text = asset_name
	extract_button.hide()
	_connect_signals_if_enabled()


func setup(p_url: String, p_name: String):
	url = p_url
	asset_name = p_name
	local_path = _build_download_path(p_name)
	if is_inside_tree():
		title_label.text = asset_name


func _on_progress_updated(p_url: String, bytes_downloaded: int, total_bytes: int):
	if p_url == url:
		_update_progress(bytes_downloaded, total_bytes)


func _on_download_completed(p_path: String):
	if p_path == local_path and not _is_extracting:
		_is_extracting = true
		_start_extraction()


func _connect_signals_if_enabled() -> void:
	var ambient_cg = CONFIG.get_instance(self)
	if ambient_cg:
		ambient_cg.signals.download_progress_updated.connect(_on_progress_updated)
		ambient_cg.signals.download_completed.connect(_on_download_completed)


func _build_download_path(asset_name: String) -> String:
	var download_path = CONFIG.get_setting(
		CONFIG.SETTING_DOWNLOAD_PATH, CONFIG.DEFAULT_DOWNLOAD_PATH
	)
	return download_path.trim_suffix("/") + "/%s" % asset_name


func _update_progress(bytes_downloaded: int, total_bytes: int) -> void:
	var progress = (float(bytes_downloaded) / float(total_bytes)) * 100.0
	progress_bar.value = progress
	status_label.text = "Downloading (%.1f%%)" % progress


func _start_extraction() -> void:
	status_label.text = "Extracting..."
	progress_bar.hide()

	var ambient_cg = CONFIG.get_instance(self)
	if ambient_cg:
		var extract_path = CONFIG.get_setting(
			CONFIG.SETTING_EXTRACT_PATH, CONFIG.DEFAULT_EXTRACT_PATH
		)
		await ambient_cg.file_handler.extract_all(local_path, extract_path)

	queue_free()
