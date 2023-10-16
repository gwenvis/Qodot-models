@tool
class_name QodotFGDModelPointClass
extends QodotFGDPointClass

## Optional - if empty, will use the game dir provided when exported.
@export_global_dir var trenchbroom_game_dir = ""
## Optional - if empty, will use the export dir provided when exported
@export var model_export_dir := ""
## Optional - if empty, will use the default scale
## Scale expression applied to model in Trenchbroom. See https://trenchbroom.github.io/manual/latest/#display-models-for-entities for more info.
@export var scale_expression := ""
@export var generate_bounding_box := true
@export var apply_rotation_on_import := true
func build_def_text(options: QodotBuildDefTextOptions = null) -> String:
	_generate_model(options)
	return super(options)

func _generate_model(options: QodotBuildDefTextOptions):
	_set_model(options)

func _set_model(options: QodotBuildDefTextOptions):
	if not scene_file:
		return 
	
	var gltf_state := GLTFState.new()
	var path = _get_export_dir(options)
	var node = _get_node()
	if node == null: return
	if not _create_gltf_file(gltf_state, path, node, options.create_ignore_files):
		printerr("could not create gltf file")
		return
	node.queue_free()
	const model_key := "model"
	const size_key := "size"
	meta_properties[model_key] = '{"path": "%s", "scale": %s }' % [
		_get_local_path(options), 
		options.scale if scale_expression.is_empty() else scale_expression
	]
	if generate_bounding_box:
		meta_properties[size_key] = _get_bounding_box(gltf_state.meshes)

func _get_node() -> Node3D:
	var node := scene_file.instantiate()
	if node is Node3D: return node as Node3D
	node.queue_free()
	printerr("Scene is not of type 'Node3D'")
	return null


func _get_export_dir(options: QodotBuildDefTextOptions) -> String:
	var tb_game_dir = options.trenchbroom_project_dir if trenchbroom_game_dir.is_empty() else trenchbroom_game_dir
	var export_dir = options.model_export_dir if model_export_dir.is_empty() else model_export_dir
	return tb_game_dir.path_join(export_dir).path_join('%s.glb' % classname)

func _get_local_path(options: QodotBuildDefTextOptions) -> String:
	var export_dir = options.model_export_dir if model_export_dir.is_empty() else model_export_dir
	return export_dir.path_join('%s.glb' % classname)

func _create_gltf_file(gltf_state: GLTFState, path: String, node: Node3D, create_ignore_files: bool) -> bool:
	var error := 0 
	var global_export_path = path
	var gltf_document := GLTFDocument.new()
	gltf_state.create_animations = false
	node.rotate_y(deg_to_rad(90))
	gltf_document.append_from_scene(node, gltf_state)
	if error != OK:
		printerr("Failed appending to gltf document", error)
		return false

	call_deferred("_save_to_file_system", gltf_document, gltf_state, global_export_path, create_ignore_files)
	return true

func _save_to_file_system(gltf_document: GLTFDocument, gltf_state: GLTFState, path: String, create_ignore_files: bool):
	var error := 0
	error = DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if error != OK:
		printerr("Failed creating dir", error)
		return 

	if create_ignore_files: _create_ignore_files(path.get_base_dir())

	error = gltf_document.write_to_filesystem(gltf_state, path)
	if error != OK:
		printerr("Failed writing to file system", error)
		return 
	print('exported model ', path)

func _create_ignore_files(path: String):
	var error := 0
	const gdIgnore = ".gdignore"
	var file = path.path_join(gdIgnore)
	if FileAccess.file_exists(file):
		return
	var fileAccess := FileAccess.open(file, FileAccess.WRITE)
	fileAccess.store_string('')
	fileAccess.close()

func _get_bounding_box(meshes: Array[GLTFMesh]) -> AABB:
	var aabb := AABB()
	for mesh in meshes:
		aabb.merge(mesh.mesh.get_mesh().get_aabb())
	return aabb