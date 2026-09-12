@tool

const UTILS = preload("res://addons/ambientcg/utils/ambient_utils.gd")
const TEMP_FILE_PATH := "user://temp_acg_tres.tres"


static func api_info_to_option_button(button: OptionButton, json: Dictionary) -> void:
	button.clear()
	button.add_item("Any")

	var types = json.get("types", [])
	for type in types:
		button.add_item(str(type).capitalize())
		button.set_item_metadata(button.get_item_count() - 1, str(type).to_lower())


static func parse_search_query_data(json: Dictionary) -> Dictionary:
	return parse_assets(json)


static func parse_assets(json: Dictionary) -> Dictionary:
	var output: Dictionary = {}
	output["result_count_total"] = json.get("totalResults", 0)
	var next_page = json.get("nextPageHttp", "")
	output["next_query_uri"] = str(next_page) if next_page != null else ""

	var assets: Array = []
	for asset_json in json.get("assets", []):
		var asset: Dictionary = {}
		asset["id"] = asset_json.get("id", "")
		asset["title"] = asset_json.get("title", "")

		var thumbnails = asset_json.get("thumbnails", {})
		asset["thumbnail"] = thumbnails.get("128-PNG", thumbnails.get("128-WEBP", ""))

		var asset_id = asset["id"].to_lower()
		if asset_id.contains("hdri"):
			asset["asset_type"] = "hdri"
		else:
			asset["asset_type"] = "material"

		var downloads: Array = []
		var implementation_uris: Dictionary = {}
		for download_json in asset_json.get("downloads", []):
			var download = {
				"id": asset["id"] + "_" + download_json.get("attributes", ""),
				"uri": download_json.get("url", ""),
				"file_size": download_json.get("size", 0),
				"extension": download_json.get("extension", ""),
				"local_file_name":
				(
					asset["id"]
					+ "_"
					+ download_json.get("attributes", "")
					+ "."
					+ download_json.get("extension", "")
				)
			}
			downloads.append(download)
			implementation_uris[download_json.get("attributes", "")] = download["uri"]

		asset["download_data"] = downloads
		asset["implementation_uris"] = implementation_uris
		assets.append(asset)

	output["assets"] = assets
	return output


static func pull_tres_dependencies(zip_reader: ZIPReader, tres_file: String) -> Dictionary:
	var content: PackedByteArray = zip_reader.read_file(tres_file, false)
	UTILS.save_buffer(TEMP_FILE_PATH, content)
	var dependencies: PackedStringArray = ResourceLoader.get_dependencies(TEMP_FILE_PATH)
	DirAccess.remove_absolute(TEMP_FILE_PATH)
	return {"tres_content": content, "dependencies": dependencies}
