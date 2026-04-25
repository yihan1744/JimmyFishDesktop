#!/usr/bin/env python3
"""
Bake Blender Mapping node transforms into UVs for glTF export compatibility.

Run: blender path/to/model.blend --background --python bake_mapping_to_uvs.py

Modellers can use Mapping nodes freely; this script bakes the transform into UVs
and removes the Mapping node so glTF export works correctly.

Output: saves to same path with "_gltf_ready" suffix (e.g. model_gltf_ready.blend).
"""
import bpy
import bmesh
import sys
import os

# Uses Blender's mathutils for exact transform (full XYZ Euler, matches internal implementation).


def get_mapping_to_image_pairs(mat):
    """Find (Mapping node, Image Texture node) pairs where Mapping feeds Image Texture."""
    pairs = []
    if not mat or not mat.node_tree:
        return pairs
    nt = mat.node_tree
    for node in nt.nodes:
        if node.type != "MAPPING":
            continue
        # Mapping output goes to Image Texture's Vector input
        for link in node.outputs[0].links:
            to_node = link.to_node
            if to_node.type == "TEX_IMAGE":
                pairs.append((node, to_node))
    return pairs


def get_mapping_values(mapping_node):
    """Get Location, Rotation, Scale and vector_type from Mapping node."""
    tx = ty = tz = 0.0
    rx = ry = rz = 0.0
    sx = sy = sz = 1.0
    vec_type = getattr(mapping_node, "vector_type", "TEXTURE")
    for inp in mapping_node.inputs:
        try:
            v = inp.default_value
            if hasattr(v, "x") and hasattr(v, "y"):
                arr = [float(v.x), float(v.y), float(v.z) if hasattr(v, "z") else 0]
            else:
                arr = list(v) if hasattr(v, "__iter__") and not isinstance(v, str) else [v]
            if inp.identifier == "Location" and len(arr) >= 3:
                tx, ty, tz = arr[0], arr[1], arr[2]
            elif inp.identifier == "Rotation" and len(arr) >= 3:
                rx, ry, rz = arr[0], arr[1], arr[2]
            elif inp.identifier == "Scale" and len(arr) >= 3:
                sx, sy, sz = arr[0], arr[1], arr[2]
        except Exception:
            pass
    return tx, ty, tz, rx, ry, rz, sx, sy, sz, vec_type


def _build_mapping_matrix(tx, ty, tz, rx, ry, rz, sx, sy, sz, vec_type):
    """Build the 4x4 transform matrix Blender uses. Texture: T*R*S, inverse for output."""
    from mathutils import Matrix, Vector, Euler
    # Forward: Translate, Rotate (Euler XYZ), Scale (along local axis)
    T = Matrix.Translation((tx, ty, tz))
    E = Euler((rx, ry, rz), "XYZ")
    R = E.to_matrix().to_4x4()
    S = Matrix.Diagonal((sx, sy, sz, 1.0))
    M = T @ R @ S
    if vec_type == "TEXTURE":
        M = M.inverted()
    return M


def apply_mapping_to_uv(uv, mapping_node):
    """Apply the transform that the Mapping node outputs (inverse for Texture type)."""
    from mathutils import Vector
    tx, ty, tz, rx, ry, rz, sx, sy, sz, vec_type = get_mapping_values(mapping_node)
    M = _build_mapping_matrix(tx, ty, tz, rx, ry, rz, sx, sy, sz, vec_type)
    p = M @ Vector((uv.x, uv.y, 0.0))
    return (p.x, p.y)


def bake_material_mapping(mat, mapping_node, image_node):
    """Bake Mapping transform into UVs for faces using this material, then remove Mapping node."""
    for obj in bpy.data.objects:
        if obj.type != "MESH":
            continue
        mesh = obj.data
        if not mesh.materials or len(mesh.materials) == 0:
            continue
        try:
            mat_index = list(mesh.materials).index(mat)
        except ValueError:
            continue
        if not mesh.uv_layers or len(mesh.uv_layers) == 0:
            continue
        if not mesh.loops:
            continue
        # Use BMesh (Blender 4+ uv_layer.data can be empty; BMesh has UVs)
        bm = bmesh.new()
        bm.from_mesh(mesh)
        if not bm.loops.layers.uv:
            bm.free()
            continue
        uv_lay = bm.loops.layers.uv[0]
        for face in bm.faces:
            if face.material_index >= len(mesh.materials):
                continue
            if face.material_index != mat_index:
                continue
            for loop in face.loops:
                uv = loop[uv_lay].uv
                u_new, v_new = apply_mapping_to_uv(uv, mapping_node)
                loop[uv_lay].uv = (u_new, v_new)
        bm.to_mesh(mesh)
        bm.free()
    # Remove Mapping node and connect TEX_COORD UV directly to Image Texture Vector
    nt = mat.node_tree
    # Find Texture Coordinate node that feeds the Mapping
    tex_coord = None
    for link in mapping_node.inputs[0].links:
        tex_coord = link.from_node
        break
    # Disconnect Mapping from Image Texture
    for link in list(mapping_node.outputs[0].links):
        nt.links.remove(link)
    # Connect TEX_COORD UV to Image Texture Vector (if we have tex_coord)
    if tex_coord and tex_coord.type == "TEX_COORD":
        vec_in = image_node.inputs.get("Vector")
        if vec_in:
            nt.links.new(tex_coord.outputs["UV"], vec_in)
    # Remove Mapping node
    nt.nodes.remove(mapping_node)


def main():
    # Ensure all mesh objects are in object mode (required for bm.to_mesh)
    for obj in bpy.data.objects:
        if obj.type == "MESH" and obj.mode != "OBJECT":
            bpy.context.view_layer.objects.active = obj
            bpy.ops.object.mode_set(mode="OBJECT")
    baked_count = 0
    for mat in bpy.data.materials:
        if mat is None or mat.node_tree is None:
            continue
        pairs = get_mapping_to_image_pairs(mat)
        for mapping_node, image_node in pairs:
            if mapping_node.name not in mat.node_tree.nodes:
                continue  # Already removed
            bake_material_mapping(mat, mapping_node, image_node)
            baked_count += 1
    # Save to new file
    path = bpy.data.filepath
    if not path:
        print("No file loaded, cannot save.", file=sys.stderr)
        return 1
    base, ext = os.path.splitext(path)
    out_path = base + "_gltf_ready" + ext
    bpy.ops.wm.save_as_mainfile(filepath=out_path)
    print(f"Baked {baked_count} Mapping node(s) into UVs. Saved to: {out_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
