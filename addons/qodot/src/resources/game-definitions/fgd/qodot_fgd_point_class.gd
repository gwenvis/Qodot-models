@tool
class_name QodotFGDPointClass
extends QodotFGDClass

func _init():
	prefix = "@PointClass"

# The scene file to associate with this PointClass
# On building the map, this scene will be instanced into the scene tree
@export_group ("Scene")
@export var scene_file: PackedScene
## Exports the model to a GLTF file so it's displayed in Trenchbroom
@export var export_model: bool

# The script file to associate with this PointClass
# On building the map, this will be attached to any brush entities created
# via this classname if no scene_file is specified
@export_group ("Scripting")
@export var script_class: Script

func generate_model():
	_set_model()

func _set_model():
	if not export_model:
		return
	if not scene_file:
		return 
	
	var gltfState := GLTFState.new()
	var path = "addons/qodot/export/" + scene_file.resource_path.replace("res://", "") + ".glb"
	if not _create_gltf_file(gltfState, path):
		return
	const model_key := "model"
	const size_key := "size"
	var model_value = "\"%s\"" % path
	meta_properties[model_key] = model_value
	meta_properties[size_key] = _get_bounding_box(gltfState.meshes)

func _create_gltf_file(gltfState: GLTFState, path: String) -> bool:
	var error := 0 
	var global_export_path := ProjectSettings.globalize_path("res://" + path)
	var gltf_document := GLTFDocument.new()
	gltfState.create_animations = false

	var node := scene_file.instantiate() as Node3D
	#node.position += Vector3(0, -8, 0)
	node.scale += Vector3(16, 16, 16)

	gltf_document.append_from_scene(node, gltfState)
	if error != OK:
		printerr("Failed appending to gltf document", error)
		return false

	call_deferred("_save_to_file_system", gltf_document, gltfState, global_export_path)
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