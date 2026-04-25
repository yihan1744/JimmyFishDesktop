#!/usr/bin/env python3
"""
Check a Blender file for common problems before adding to assets/pet/.

Run: blender path/to/model.blend --background --python tools/check_blend_file.py

Outputs JSON to stdout:
  {"unpacked": bool, "unpacked_count": int, "unpacked_names": [...], "mapping_nodes": int}

Exit codes:
  1 = RED FLAG: unpacked resources (must pack in Blender before copying)
  0 = OK or warnings only (mapping_nodes > 0 is a warning, not a hard fail)
"""
import bpy
import json
import sys


def count_mapping_nodes():
    """Count Mapping nodes that feed Image Texture (affects glTF export)."""
    count = 0
    for mat in bpy.data.materials:
        if not mat or not mat.node_tree:
            continue
        for node in mat.node_tree.nodes:
            if node.type != "MAPPING":
                continue
            for link in node.outputs[0].links:
                if link.to_node.type == "TEX_IMAGE":
                    count += 1
                    break
    return count


def get_unpacked_images():
    """Return list of image names that are unpacked (external files)."""
    unpacked = []
    skip_names = ("Render Result", "Viewer Node")
    for img in bpy.data.images:
        if img.name in skip_names:
            continue
        if img.packed_file is None:
            # Unpacked: has external filepath or is generated
            if img.filepath and img.filepath.strip():
                unpacked.append(img.name)
    return unpacked


def main():
    unpacked = get_unpacked_images()
    mapping_count = count_mapping_nodes()

    result = {
        "unpacked": len(unpacked) > 0,
        "unpacked_count": len(unpacked),
        "unpacked_names": unpacked,
        "mapping_nodes": mapping_count,
    }
    print(json.dumps(result))

    # Exit 1 if unpacked (RED FLAG - cannot accept)
    if unpacked:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
