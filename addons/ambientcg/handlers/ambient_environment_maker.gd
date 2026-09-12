@tool


static func make_environment_resource(files: PackedStringArray) -> Environment:
	var sky_res := Sky.new()
	var sky_mat := PanoramaSkyMaterial.new()

	for file in files:
		var ext = file.get_extension().to_lower()
		if ext in ["exr", "hdr"]:
			var tex = _load_texture(file)
			if tex:
				sky_mat.panorama = tex
				break

	sky_res.sky_material = sky_mat

	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = sky_res

	# ACES Tone mapping is generally better for HDRIs
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	environment.glow_enabled = true

	return environment


static func _load_texture(path: String) -> Texture2D:
	if path.begins_with("res://") and Engine.is_editor_hint():
		return load(path)

	# Fallback for user:// or non-imported files
	var img = Image.load_from_file(path)
	if img and not img.is_empty():
		return ImageTexture.create_from_image(img)
	return null
