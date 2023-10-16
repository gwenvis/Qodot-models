@tool
class_name QodotBuildDefTextOptions

var trenchbroom_project_dir: String
var model_export_dir: String
var create_ignore_files: bool
var scale: int 

func _init():
    scale = 16
    create_ignore_files = true
    model_export_dir = "trenchbroom/generated/models"
    trenchbroom_project_dir = (ProjectSettings.globalize_path("res://") 
        if Engine.is_editor_hint()
        else OS.get_executable_path().get_base_dir()
    )
    if Engine.is_editor_hint(): trenchbroom_project_dir = ProjectSettings.globalize_path("res://")
    else: trenchbroom_project_dir = OS.get_executable_path().get_base_dir()