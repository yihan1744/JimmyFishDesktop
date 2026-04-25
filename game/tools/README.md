# Blender → glTF Tools

## check_blend_file.py

Check a .blend file for problems before adding to assets. Run via Blender headless; outputs JSON.

**Usage:**
```bash
blender path/to/model.blend --background --python tools/check_blend_file.py
```

**Wrapper (human-readable output):**
```bash
python3 tools/check_blend_asset.py assets/pet/<file>.blend
```

**Output:** `unpacked` (RED FLAG if true), `mapping_nodes` (WARNING if > 0). See `docs/pipeline/blender_asset_incoming.md`.

---

## bake_mapping_to_uvs.py

Bake Blender Mapping node transforms into UVs for glTF export. glTF does not support Mapping nodes; this script bakes the transform into UVs and removes the node.

**Usage:**
```bash
blender path/to/model.blend --background --python tools/bake_mapping_to_uvs.py
```

**Output:** `path/to/model_gltf_ready.blend` (original unchanged).

**What it does:**
- Finds materials with Mapping → Image Texture chains
- Applies the transform (location, rotation, scale) to UVs of faces using that material
- Removes the Mapping node and connects Texture Coordinate UV directly to Image Texture
- Uses Blender's mathutils for exact transform (full XYZ Euler)

---

## Other Blender→glTF limitations

Common Blender features not supported in glTF that may need similar tooling:

| Blender feature | glTF support | Workaround |
|-----------------|--------------|------------|
| **Mapping node** | Not supported | ✅ This script bakes into UVs |
| Texture Coordinate: Generated, Object, Normal | Only UV supported | Bake to texture or use UV |
| Procedural textures (Noise, etc.) | Not supported | Bake to image texture |
| Multiple UV layers per material | Godot uses first only | Use single UV map or merge |
| Complex node trees | Simplified to PBR | Bake or simplify |

**Q: Is there an export format that supports the Mapping node?**  
glTF has the `KHR_texture_transform` extension (offset, rotation, scale), but Blender's glTF exporter does not emit it. Godot's glTF importer support for it is limited. So for glTF/glb, baking into UVs is the reliable approach. FBX and other formats have varying support; none are a clear "use Mapping node natively" path for the Blender → Godot pipeline.
