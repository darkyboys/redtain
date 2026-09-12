@tool
extends Node

var config: Script
var utils: Script
var logger: Node
var signals: Node
var material_maker: Script
var environment_maker: Script


func extract_all(source_file: String, target_path: String = "", options: Dictionary = {}) -> void:
	_log_info("Starting automatic extraction for: %s" % source_file)

	var file_sys = _get_filesystem()
	var reader = _open_zip_reader(source_file)
	if not reader:
		return

	var files = reader.get_files()
	var extraction_path = await _get_extraction_path(target_path)
	if extraction_path.is_empty():
		reader.close()
		return

	var final_extract_path = _prepare_extraction_path(extraction_path, source_file)
	_emit_extraction_started(source_file.get_file().get_basename())

	if DirAccess.dir_exists_absolute(final_extract_path):
		utils.clean_dir_content(final_extract_path)

	var saved_files = _extract_zip_contents(reader, files, final_extract_path, options, file_sys)
	_refresh_filesystem(file_sys)
	reader.close()

	await _wait_for_import(saved_files, file_sys)
	await _finalize_extraction(
		source_file.get_file().get_basename(), saved_files, final_extract_path, options, file_sys
	)

	_log_info("Success! Resources created and folders populated")
	_emit_extraction_completed(source_file.get_file().get_basename(), final_extract_path)
	DirAccess.remove_absolute(source_file)


func _extract_zip_contents(
	reader: ZIPReader,
	files: PackedStringArray,
	target_dir: String,
	options: Dictionary,
	file_sys: Variant
) -> PackedStringArray:
	utils.ensure_dir(target_dir)

	var res_regex = RegEx.new()
	res_regex.compile("\\d+K")

	var saved_files: PackedStringArray
	for file in files:
		var ext = file.get_extension().to_lower()
		if ext in ["blend", "mtlx", "usdc", "usdz"]:
			continue

		if ext in ["jpg", "jpeg", "png"] and not res_regex.search(file):
			continue

		var file_data: PackedByteArray = reader.read_file(file)
		var new_file_path = target_dir.path_join(file.get_file())

		var fs := FileAccess.open(new_file_path, FileAccess.WRITE)
		if fs:
			fs.store_buffer(file_data)
			fs.close()
			if file_sys:
				file_sys.update_file(new_file_path)

			saved_files.append(new_file_path)

			if ext in ["jpg", "jpeg", "png"] and options.get("use_custom_size", false):
				_process_image_scaling(new_file_path, options)
				if file_sys:
					file_sys.update_file(new_file_path)

	return saved_files


func _finalize_extraction(
	asset_name: String,
	saved_files: PackedStringArray,
	final_extract_path: String,
	options: Dictionary,
	file_sys: Variant
) -> void:
	var is_hdri := asset_name.to_lower().contains("hdri")
	var mat_dir: String = config.get_setting(
		config.SETTING_MATERIAL_DIR, config.DEFAULT_MATERIAL_DIR
	)
	var env_dir: String = config.get_setting(
		config.SETTING_ENVIRONMENT_DIR, config.DEFAULT_ENVIRONMENT_DIR
	)
	var save_dir := env_dir if is_hdri else mat_dir
	var mat_save_path: String = save_dir.path_join(asset_name + ".tres")

	var extracted_tres_path: String = ""
	for f in saved_files:
		if f.get_extension().to_lower() == "tres":
			extracted_tres_path = f
			break

	if not extracted_tres_path.is_empty():
		var tres_content = FileAccess.get_file_as_string(extracted_tres_path)
		var fixed_content = _fix_tres_texture_paths(tres_content, final_extract_path)
		var out_file = FileAccess.open(mat_save_path, FileAccess.WRITE)
		if out_file:
			out_file.store_string(fixed_content)
			out_file.close()
		DirAccess.remove_absolute(extracted_tres_path)
	else:
		var res: Resource
		if is_hdri:
			res = environment_maker.make_environment_resource(saved_files)
		elif options.get("enable_packing", false):
			res = material_maker.make_orm_material(saved_files, options)
		else:
			res = material_maker.make_standard_material(saved_files, options)

		ResourceSaver.save(res, mat_save_path)

	if file_sys:
		file_sys.update_file(mat_save_path)


func _fix_tres_texture_paths(content: String, extract_folder: String) -> String:
	var path_regex = RegEx.new()
	path_regex.compile('path="([^"]+)"')
	var result = content
	for match in path_regex.search_all(content):
		var original_path = match.get_string(1)
		if not original_path.begins_with("res://"):
			var absolute_path = extract_folder.path_join(original_path)
			result = result.replace('path="%s"' % original_path, 'path="%s"' % absolute_path)
	return result


func _process_image_scaling(path: String, options: Dictionary) -> void:
	var img = Image.load_from_file(path)
	if not img or img.is_empty():
		return

	var current_size = img.get_size()
	var target_size = options.get("img_size", current_size)

	if target_size != current_size:
		img.resize(target_size.x, target_size.y, Image.INTERPOLATE_BILINEAR)
		var ext = path.get_extension().to_lower()
		if ext in ["jpg", "jpeg"]:
			img.save_jpg(path)
		elif ext == "png":
			img.save_png(path)


func _get_extraction_path(target_path: String) -> String:
	var extraction_path: String = target_path
	if extraction_path.is_empty():
		extraction_path = await open_directory_dialog_for_path("Select path to Extract to")

	if extraction_path.is_empty():
		_log_warn("Extraction cancelled: No directory selected")

	return extraction_path


func open_directory_dialog_for_path(title: String) -> String:
	if not Engine.is_editor_hint():
		return "user://test_extract/"

	var dialog := FileDialog.new()
	add_child(dialog)
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	dialog.title = title
	dialog.current_dir = config.get_setting(
		config.SETTING_EXTRACT_PATH, config.DEFAULT_EXTRACT_PATH
	)
	dialog.show()
	return await dialog.dir_selected


func _wait_for_import(files: PackedStringArray, file_sys: Variant) -> void:
	var timeout = 5.0
	while timeout > 0:
		var missing_files = false
		for f in files:
			if not ResourceLoader.exists(f):
				missing_files = true
				break

		if not missing_files:
			break

		await get_tree().create_timer(0.5).timeout
		timeout -= 0.5
		if file_sys:
			file_sys.scan()


func _get_filesystem() -> Variant:
	if Engine.is_editor_hint() and is_instance_valid(EditorInterface):
		return EditorInterface.get_resource_filesystem()
	return null


func _refresh_filesystem(file_sys: Variant) -> void:
	if file_sys:
		file_sys.scan()
		file_sys.scan_sources()


func _open_zip_reader(source_file: String) -> ZIPReader:
	var reader := ZIPReader.new()
	var err = reader.open(source_file)
	if err != OK:
		_log_error("Failed to open ZIP file: %d" % err)
		if signals:
			signals.extraction_failed.emit(source_file.get_file(), "Failed to open ZIP")
		return null
	return reader


func _prepare_extraction_path(extraction_path: String, source_file: String) -> String:
	var asset_name: String = source_file.get_file().get_basename()
	return extraction_path.path_join(asset_name)


func _emit_extraction_started(asset_name: String) -> void:
	if signals:
		signals.extraction_started.emit(asset_name)


func _emit_extraction_completed(asset_name: String, final_extract_path: String) -> void:
	if signals:
		signals.extraction_completed.emit(asset_name, {"path": final_extract_path})


func _log_info(message: String) -> void:
	if logger:
		logger.info(message, "Extractor")


func _log_warn(message: String) -> void:
	if logger:
		logger.warn(message, "Extractor")


func _log_error(message: String) -> void:
	if logger:
		logger.error(message, "Extractor")
