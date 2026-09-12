@tool
extends Control

signal pop_up_closed(accepted: bool)

const CONFIG = preload("res://addons/ambientcg/core/ambient_config.gd")
const UI_HELPERS = preload("res://addons/ambientcg/utils/ui_helpers.gd")

var active: bool = false

@onready var tab_container: TabContainer = %TabContainer


func _ready() -> void:
	var ambient_cg = CONFIG.get_instance(self)
	if ambient_cg:
		ambient_cg.file_handler.check_dirs()
		ambient_cg.logger.info("AmbientCG UI initialized and folders checked", "UI")


func open() -> void:
	active = true


func popup_accept(title: String, content: String, ok_text := "Ok", cancel_text := "Cancel") -> bool:
	var helpers = UI_HELPERS.new()
	var result = await helpers.show_confirmation_dialog(self, title, content, ok_text, cancel_text)
	helpers.queue_free()
	return result
