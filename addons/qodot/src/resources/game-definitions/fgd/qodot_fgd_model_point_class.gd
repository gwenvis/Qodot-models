@tool
class_name QodotFGDModelPointClass
extends QodotFGDPointClass

@export var scale := 16.0

func build_def_text() -> String:
	_generate_model()
	return super()

func _generate_model():
	_set_model()

func _set_model():
	if not scene_file:
		return 
	
	var gltf_state := GLTFState.new()
	var path = "addons/qodot/export/" + scene_file.resource_path.replace("res://", "") + ".glb"
	if not _create_gltf_file(gltf_state, path):
		printerr("could not create gltf file")
		return
	const model_key := "model"
	const size_key := "size"
	var model_value = "\"%s\"" % path
	meta_properties[model_key] = model_value
	meta_properties[size_key] = _get_bounding_box(gltf_state.meshes)

func _create_gltf_file(gltf_state: GLTFState, path: String) -> bool:
	var error := 0 
	var global_export_path := ProjectSettings.globalize_path("res://" + path)
	var gltf_document := GLTFDocument.new()
	gltf_state.create_animations = false

	var node := scene_file.instantiate() as Node3D
	node.scale += Vector3(scale, scale, scale)

	gltf_document.append_from_scene(node, gltf_state)
	if error != OK:
		printerr("Failed appending to gltf document", error)
		return false

	call_deferred("_save_to_file_system", gltf_document, gltf_state, global_export_path)
	return true

func _save_to_file_system(gltf_document: GLTFDocument, gltf_state: GLTFState, export_path: String):
	var error := 0
	error = DirAccess.make_dir_recursive_absolute(export_path.get_base_dir())
	if error != OK:
		printerr("Failed creating dir", error)
		return 

	error = gltf_document.write_to_filesystem(gltf_state, export_path)
	if error != OK:
		printerr("Failed writing to file system", error)
		return 
	print('exported model ', export_path)

func _get_bounding_box(meshes: Array[GLTFMesh]) -> AABB:
	var aabb := AABB()
	for mesh in meshes:
		aabb.merge(mesh.mesh.get_mesh().get_aabb())
	return aabb