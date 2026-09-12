@tool
# AmbientMaterialMaker
# Utility class for creating Godot materials from extracted texture files.


static func make_standard_material(
	files: PackedStringArray, options: Dictionary
) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.uv1_triplanar = options.get("use_triplanar_uv", false)

	for file: String in files:
		if not FileAccess.file_exists(file):
			continue

		var tex = _load_texture(file)
		if not tex:
			continue

		var f_lower = file.to_lower()
		if f_lower.contains("color"):
			material.albedo_texture = tex
		if f_lower.contains("normal"):
			material.normal_enabled = true
			material.normal_texture = tex
		if f_lower.contains("metalness"):
			material.metallic_texture = tex
		if f_lower.contains("rough"):
			material.roughness_texture = tex
		if f_lower.contains("displacement") or f_lower.contains("height"):
			material.heightmap_enabled = not options.get("use_triplanar_uv", false)
			material.heightmap_texture = tex

	return material


static func _load_texture(path: String) -> Texture2D:
	if path.begins_with("res://") and Engine.is_editor_hint():
		return load(path)

	# Fallback for user:// or non-imported files
	var img = Image.load_from_file(path)
	if img and not img.is_empty():
		return ImageTexture.create_from_image(img)
	return null


static func make_orm_material(_files: PackedStringArray, _options: Dictionary) -> ORMMaterial3D:
	var material := ORMMaterial3D.new()
	# TODO: Implement ORM texture packing logic
	return material
