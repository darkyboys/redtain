@tool
extends Node

# API & Discovery
signal api_initialized(info: Dictionary)
signal search_completed(results: Dictionary)

# Download Lifecycle
signal download_requested(asset_id: String, quality: String)
signal download_started(url: String, file_name: String)
signal download_progress_updated(url: String, bytes_received: int, total_bytes: int)
signal download_completed(file_path: String)
signal download_failed(url: String, reason: String)

# Extraction & Generation
signal extraction_started(asset_name: String)
signal extraction_completed(asset_name: String, result_data: Dictionary)
signal extraction_failed(asset_name: String, reason: String)

# Notifications
signal notification_requested(message: String, type: String)
