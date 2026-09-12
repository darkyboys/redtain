@tool
extends PanelContainer

const UI_HELPERS = preload("res://addons/ambientcg/utils/ui_helpers.gd")

var asset_data: Dictionary = {}
var main_owner: Control
var browser: Control

@onready var texture_rect: TextureRect = %TextureRect
@onready var download_button: Button = %Button


func setup(data: Dictionary, p_owner: Control, p_browser: Control) -> void:
	asset_data = data
	main_owner = p_owner
	browser = p_browser

	var thumbnail_url = asset_data.get("thumbnail", "")

	if not thumbnail_url.is_empty():
		_load_thumbnail(thumbnail_url)


func _load_thumbnail(url: String) -> void:
	var helpers = UI_HELPERS.new()
	var texture = await helpers.load_image_from_url(self, url)
	helpers.queue_free()
	if texture:
		texture_rect.texture = texture


func _on_button_pressed() -> void:
	if browser and browser.has_method("display_asset_details"):
		browser.display_asset_details(asset_data)
