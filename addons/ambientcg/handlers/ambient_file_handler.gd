@tool
extends Node

var config: Script
var utils: Script
var logger: Node
var signals: Node
var api: Node
var material_maker: Script
var environment_maker: Script

var downloader: Node
var extractor: Node


func _ready() -> void:
	downloader = preload("res://addons/ambientcg/handlers/ambient_downloader.gd").new()
	extractor = preload("res://addons/ambientcg/handlers/ambient_extractor.gd").new()

	downloader.name = "Downloader"
	extractor.name = "Extractor"

	add_child(downloader)
	add_child(extractor)

	downloader.config = config
	downloader.logger = logger
	downloader.signals = signals
	downloader.api = api
	downloader.utils = utils

	extractor.config = config
	extractor.utils = utils
	extractor.logger = logger
	extractor.signals = signals
	extractor.material_maker = material_maker
	extractor.environment_maker = environment_maker


func download_file_from_data(file_information: Dictionary, source_window: Node) -> void:
	check_dirs()
	downloader.download_file_from_data(file_information, source_window)


func extract_all(source_file: String, target_path: String = "", options: Dictionary = {}) -> void:
	extractor.extract_all(source_file, target_path, options)


func check_dirs() -> void:
	var paths = [
		config.get_setting(config.SETTING_DOWNLOAD_PATH, config.DEFAULT_DOWNLOAD_PATH),
		config.get_setting(config.SETTING_EXTRACT_PATH, config.DEFAULT_EXTRACT_PATH),
		config.get_setting(config.SETTING_MATERIAL_DIR, config.DEFAULT_MATERIAL_DIR),
		config.get_setting(config.SETTING_ENVIRONMENT_DIR, config.DEFAULT_ENVIRONMENT_DIR)
	]
	for p in paths:
		utils.ensure_dir(p)
