@tool
extends VBoxContainer

const DOWNLOAD_ITEM_SCENE = preload(
	"res://addons/ambientcg/ui/components/download/download_item.tscn"
)
const CONFIG = preload("res://addons/ambientcg/core/ambient_config.gd")
const UI_HELPERS = preload("res://addons/ambientcg/utils/ui_helpers.gd")

var current_asset_id: String = ""
var asset_data: Dictionary = {}

var _parsed_implementations: Array[Dictionary] = []
var _last_request_id: int = 0

@onready var asset_inspector: VBoxContainer = %AssetInspector
@onready var sidebar_placeholder: CenterContainer = %SidebarPlaceholder
@onready var asset_title: Label = %AssetTitle
@onready var preview_rect: TextureRect = %PreviewRect
@onready var groups_container: VBoxContainer = %GroupsContainer
@onready var download_list: VBoxContainer = %DownloadList
@onready var zip_radio: CheckBox = %ZipRadio
@onready var usdz_radio: CheckBox = %UsdzRadio
@onready var id_edit: LineEdit = %IdEdit
@onready var load_button: Button = %LoadButton


func _ready() -> void:
	asset_inspector.hide()
	sidebar_placeholder.show()
	var ambient_cg = CONFIG.get_instance(self)
	if ambient_cg:
		ambient_cg.signals.download_started.connect(_on_download_started)
	zip_radio.toggled.connect(_on_container_changed)
	usdz_radio.toggled.connect(_on_container_changed)
	id_edit.text_submitted.connect(_on_manual_id_submitted)
	load_button.pressed.connect(func(): _on_manual_id_submitted(id_edit.text))


func display_asset(asset: Dictionary) -> void:
	var new_asset_id = asset.get("id", "")

	if current_asset_id == new_asset_id and not current_asset_id.is_empty():
		asset_inspector.show()
		sidebar_placeholder.hide()
		return

	current_asset_id = new_asset_id
	asset_inspector.hide()
	sidebar_placeholder.show()

	for child in groups_container.get_children():
		child.queue_free()

	asset_data = asset

	if asset_data.is_empty():
		var ambient_cg = CONFIG.get_instance(self)
		if ambient_cg:
			ambient_cg.logger.error("Failed to fetch asset details", "UI")
		return

	asset_title.text = current_asset_id

	_last_request_id += 1
	var request_id = _last_request_id

	var thumbnail_url = asset_data.get("thumbnail", "")
	if not thumbnail_url.is_empty():
		_load_preview(thumbnail_url, request_id)
	else:
		preview_rect.texture = null

	sidebar_placeholder.hide()
	asset_inspector.show()

	_parsed_implementations.clear()
	if asset_data.has("download_data"):
		_parsed_implementations.append_array(asset_data["download_data"])
		_build_download_ui()
	else:
		var err_label = Label.new()
		err_label.text = "No download data available."
		err_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		groups_container.add_child(err_label)


func _on_container_changed(_toggled: bool):
	if _toggled:
		_build_download_ui()


func _build_download_ui() -> void:
	if not CONFIG.is_plugin_enabled():
		return

	for c in groups_container.get_children():
		c.queue_free()

	if _parsed_implementations.is_empty():
		var err_label = Label.new()
		err_label.text = "Failed to load downloads."
		err_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		groups_container.add_child(err_label)
		return

	var filter_ext = "zip" if zip_radio.button_pressed else "usdz"
	var is_hdri = asset_data.get("asset_type", "") == "hdri"

	var grouped_data = _group_implementations(_parsed_implementations, filter_ext, is_hdri)
	var group_names = ["JPG", "PNG", "Environment" if is_hdri else "Other"]

	for fmt in group_names:
		var list = grouped_data.get(fmt, [])
		if list.is_empty():
			continue

		list.sort_custom(_sort_by_resolution)

		var group_vbox = VBoxContainer.new()
		group_vbox.add_theme_constant_override("separation", 5)

		var group_label = Label.new()
		group_label.text = fmt + " Formats"
		group_label.add_theme_font_size_override("font_size", 14)
		group_label.add_theme_color_override("font_color", Color(0.4, 0.7, 1.0))
		group_vbox.add_child(group_label)

		var columns_hbox = HBoxContainer.new()
		columns_hbox.add_theme_constant_override("separation", 5)
		group_vbox.add_child(columns_hbox)

		var col1 = VBoxContainer.new()
		col1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col1.add_theme_constant_override("separation", 5)
		columns_hbox.add_child(col1)

		var col2 = VBoxContainer.new()
		col2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col2.add_theme_constant_override("separation", 5)
		columns_hbox.add_child(col2)

		var half_point = ceil(list.size() / 2.0)
		for i in range(list.size()):
			var opt = list[i]
			var btn = Button.new()
			var ambient_cg = CONFIG.get_instance(self)
			if ambient_cg:
				var file_size = ambient_cg.Utils.format_file_size(opt.get("file_size", 0))
				btn.text = (
					opt.get("local_file_name", "").replace("." + filter_ext, "").replace(
						current_asset_id + "_", ""
					)
					+ " ("
					+ file_size
					+ ")"
				)
				btn.add_theme_font_size_override("font_size", 11)
				btn.custom_minimum_size = Vector2(100, 30)
				btn.pressed.connect(
					func(): ambient_cg.file_handler.download_file_from_data(opt, self)
				)
			else:
				btn.text = str(opt.get("file_size", 0)) + " bytes"
				btn.add_theme_font_size_override("font_size", 11)
				btn.custom_minimum_size = Vector2(100, 30)

			if i < half_point:
				col1.add_child(btn)
			else:
				col2.add_child(btn)

		groups_container.add_child(group_vbox)


func _sort_by_resolution(a: Dictionary, b: Dictionary) -> bool:
	var res_a = _extract_res(a.get("local_file_name", ""))
	var res_b = _extract_res(b.get("local_file_name", ""))
	return res_a < res_b


func _extract_res(file_name: String) -> int:
	var regex = RegEx.new()
	regex.compile("(\\d+)K")
	var result = regex.search(file_name)
	if result:
		return result.get_string(1).to_int()
	return 0


func _load_preview(url: String, request_id: int) -> void:
	var helpers = UI_HELPERS.new()
	var texture = await helpers.load_image_from_url(self, url)
	helpers.queue_free()

	if request_id != _last_request_id:
		return

	if texture:
		preview_rect.texture = texture


func _on_download_started(_url: String, asset_name: String) -> void:
	var item = DOWNLOAD_ITEM_SCENE.instantiate()
	download_list.add_child(item)
	item.setup(_url, asset_name)


func _group_implementations(
	implementations: Array[Dictionary], filter_ext: String, is_hdri: bool
) -> Dictionary:
	var grouped = {"JPG": [], "PNG": [], "Environment": [], "Other": []}

	for opt in implementations:
		var file_name = str(opt.get("local_file_name", "")).to_lower()
		if not file_name.ends_with(filter_ext):
			continue

		if is_hdri:
			grouped["Environment"].append(opt)
		elif file_name.contains("jpg"):
			grouped["JPG"].append(opt)
		elif file_name.contains("png"):
			grouped["PNG"].append(opt)
		else:
			grouped["Other"].append(opt)

	return grouped


func _on_manual_id_submitted(id: String) -> void:
	if id.is_empty():
		return

	var ambient_cg = CONFIG.get_instance(self)
	if not ambient_cg:
		return

	# Show placeholder/loading state
	asset_inspector.hide()
	sidebar_placeholder.show()
	var placeholder_label = sidebar_placeholder.get_node("Label")
	var original_text = placeholder_label.text
	placeholder_label.text = "Fetching asset %s..." % id

	var result = await ambient_cg.api.search_assets("", "Any", "", id)
	var parsed = ambient_cg.Parser.parse_search_query_data(result)
	var assets = parsed.get("assets", [])

	if assets.is_empty():
		placeholder_label.text = "Asset '%s' not found." % id
		await get_tree().create_timer(3.0).timeout
		placeholder_label.text = original_text
		return

	# Find exact match or just take the first one
	var found_asset = assets[0]
	for a in assets:
		if a.get("id", "").to_lower() == id.to_lower():
			found_asset = a
			break

	display_asset(found_asset)
	placeholder_label.text = original_text
