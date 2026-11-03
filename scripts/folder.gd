extends StaticBody3D
class_name ArchiveFolder

# One readable case file.
#
# The gameplay data lives in exported fields so each instance can be configured
# entirely in the Inspector or in Archive.tscn. The script handles only the
# in-world presentation (highlighting and the floating label).

## Title shown in the HUD, in the document window, and on the floating label.
@export var folder_title: String = "UNTITLED FILE"

## The front page, authored per-instance in the scene.
@export_multiline var document_text: String = ""

## The reverse page. Flip in the document UI switches between the two.
@export_multiline var document_back_text: String = ""

@export_group("Russian localization")
## Optional Russian title. Empty values fall back to the English fields.
@export var folder_title_ru: String = ""
@export_multiline var document_text_ru: String = ""
@export_multiline var document_back_text_ru: String = ""

@export_group("Gameplay")
## Whether this file contains a deliberate archival error.
@export var has_error: bool = false

## Used by Archive.gd to detect the special "signature" story file.
@export_enum("none", "date", "signature", "ledger") var error_type: String = "none"

@onready var cover: MeshInstance3D = $Cover
@onready var pages: MeshInstance3D = $Pages
@onready var tab: MeshInstance3D = $Tab
@onready var title_label: Label3D = $TitleLabel

## Runtime-only bookkeeping. These reset whenever the scene is restarted.
var inspected: bool = false
var has_been_opened: bool = false
var has_been_closed: bool = false

var _is_highlighted: bool = false
var _visual_meshes: Array[MeshInstance3D] = []
var _highlight_material: StandardMaterial3D


func _ready() -> void:
	add_to_group("folders")
	_visual_meshes = [cover, pages, tab]
	_refresh_title_label()
	title_label.visible = false
	Loc.locale_changed.connect(_on_locale_changed)

	# Build one shared amber material. It is applied as an override while the
	# interaction ray points at this file, and removed when the ray leaves.
	_highlight_material = StandardMaterial3D.new()
	_highlight_material.albedo_color = Color(0.72, 0.52, 0.22)
	_highlight_material.roughness = 0.55
	_highlight_material.metallic = 0.0
	_highlight_material.emission_enabled = true
	_highlight_material.emission = Color(1.0, 0.55, 0.16)
	_highlight_material.emission_energy_multiplier = 2.4


## Returns the title for the active language.
func get_localized_title() -> String:
	if Loc.locale == "ru" and not folder_title_ru.strip_edges().is_empty():
		return folder_title_ru
	return folder_title


## Returns the front page for the active language.
func get_localized_document_text() -> String:
	if Loc.locale == "ru" and not document_text_ru.strip_edges().is_empty():
		return document_text_ru
	return document_text


## Returns the reverse page for the active language.
func get_localized_document_back_text() -> String:
	if Loc.locale == "ru" and not document_back_text_ru.strip_edges().is_empty():
		return document_back_text_ru
	return document_back_text


func _on_locale_changed(_new_locale: String) -> void:
	_refresh_title_label()


func _refresh_title_label() -> void:
	title_label.text = get_localized_title().to_upper()


## Toggles the emission highlight. Called by ArchivePlayer's interaction ray.
func set_highlighted(highlighted: bool) -> void:
	if _is_highlighted == highlighted:
		return
	_is_highlighted = highlighted

	for mesh in _visual_meshes:
		mesh.material_override = _highlight_material if highlighted else null

	# The floating title only appears when the ray is on the file, which keeps
	# the desk composition clean and avoids overlapping 3D labels.
	title_label.visible = highlighted
	title_label.modulate = Color(1.0, 0.78, 0.42) if highlighted else Color(0.84, 0.82, 0.7)
	title_label.outline_modulate = Color(0.02, 0.025, 0.025, 0.9)
