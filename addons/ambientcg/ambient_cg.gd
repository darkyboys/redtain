@tool
extends Node

const Config = preload("res://addons/ambientcg/core/ambient_config.gd")
const Utils = preload("res://addons/ambientcg/utils/ambient_utils.gd")
const Parser = preload("res://addons/ambientcg/core/ambient_parser.gd")
const MaterialMaker = preload("res://addons/ambientcg/handlers/ambient_material_maker.gd")
const EnvironmentMaker = preload("res://addons/ambientcg/handlers/ambient_environment_maker.gd")

var signals: Node
var logger: Node
var api: Node
var file_handler: Node

var api_information: Dictionary = {}


func _enter_tree() -> void:
	_initialize_modules()


func _initialize_modules() -> void:
	signals = preload("res://addons/ambientcg/core/ambient_signals.gd").new()
	logger = preload("res://addons/ambientcg/core/ambient_logger.gd").new()
	api = preload("res://addons/ambientcg/core/ambient_api.gd").new()
	file_handler = preload("res://addons/ambientcg/handlers/ambient_file_handler.gd").new()

	signals.name = "Signals"
	logger.name = "Logger"
	api.name = "API"
	file_handler.name = "FileHandler"

	logger.set("signals", signals)

	api.set("config", Config)
	api.set("parser", Parser)
	api.set("logger", logger)
	api.set("signals", signals)
	api.set("manager", self)

	file_handler.set("config", Config)
	file_handler.set("utils", Utils)
	file_handler.set("logger", logger)
	file_handler.set("signals", signals)
	file_handler.set("api", api)
	file_handler.set("material_maker", MaterialMaker)
	file_handler.set("environment_maker", EnvironmentMaker)

	add_child(signals)
	add_child(logger)
	add_child(api)
	add_child(file_handler)


func _exit_tree() -> void:
	if is_instance_valid(file_handler):
		file_handler.queue_free()
	if is_instance_valid(api):
		api.queue_free()
	if is_instance_valid(logger):
		logger.queue_free()
	if is_instance_valid(signals):
		signals.queue_free()
