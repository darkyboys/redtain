@tool
extends Node

const Config = preload("res://addons/ambientcg/core/ambient_config.gd")

var signals: Node


func _log(message: String, category: String, level: String) -> void:
	var time = Time.get_time_string_from_system()
	print("%s [%s] [%s] [%s] %s" % [Config.get_plugin_name(), time, level, category, message])


func info(message: String, category: String = "General") -> void:
	_log(message, category, "INFO")


func warn(message: String, category: String = "General") -> void:
	_log(message, category, "WARN")


func error(message: String, category: String = "General") -> void:
	_log(message, category, "ERROR")
	if signals:
		signals.notification_requested.emit(message, "error")


func debug(message: String, category: String = "General") -> void:
	if OS.is_stdout_verbose() or true:
		_log(message, category, "DEBUG")
