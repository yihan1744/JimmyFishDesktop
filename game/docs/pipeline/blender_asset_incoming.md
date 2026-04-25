# Blender Asset Incoming Pipeline

When you add a `.blend` file to `assets/pet/`, run this workflow to catch problems and fix them before use.

---

## Step 1: Check the file

Run the check (from project root):

```bash
python3 tools/check_blend_asset.py assets/pet/<filename>.blend
```

Or raw JSON: `blender assets/pet/<filename>.blend --background --python tools/check_blend_file.py`

The script outputs JSON to stdout and uses exit codes:

| Result | Meaning |
|--------|---------|
| `unpacked: true` | **RED FLAG** — Cannot accept. External resources are not packed. |
| `mapping_nodes > 0` | **WARNING** — May not export well to glTF. Texture position/rotation may be wrong in Godot. |

---

## Problem 1: Unpacked resources (RED FLAG)

**Symptom:** `unpacked: true`, `unpacked_names` lists image(s).

**Action:** Do **not** accept the file. Tell the user:

> This .blend has unpacked resources (e.g. [list names]). It must be packed in Blender before copying to the project.
>
> In Blender: **File → External Data → Pack Resources** (or "Pack All into .blend"). Save, then copy the .blend to `assets/pet/` again.

The user must fix this in Blender and copy the file over again.

---

## Problem 2: Mapping nodes (WARNING)

**Symptom:** `mapping_nodes > 0`. glTF does not support Blender's Mapping node; textures may appear wrong in Godot.

**Workflow:**

1. **Try import first** — Let Godot import the .blend. User opens the imported scene and examines texture position/rotation.
2. **If user says it's wrong** — Run the UV fix:
   - Run the bake script: `blender assets/pet/<filename>.blend --background --python tools/bake_mapping_to_uvs.py`
   - This creates `<filename>_gltf_ready.blend`
3. **User examines again** — Import `_gltf_ready.blend` in Godot, check texture.
4. **If correct** — Done. Replace the original with the _gltf_ready version:
   - **Update scene references:** If the original was loaded into the main scene (or any scene) for testing, replace the path in those scene files: change `res://assets/pet/<filename>.blend` to `res://assets/pet/<filename>_gltf_ready.blend`. Otherwise Godot will show "scene cannot open because missing" error.
   - Remove `assets/pet/<filename>.blend` (original)
   - Remove `assets/pet/<filename>.blend.import` (orphaned import)
   - Keep `assets/pet/<filename>_gltf_ready.blend` as the active asset (do not rename)

---

## Quick reference

| Check result | Action |
|--------------|--------|
| Unpacked | **Reject.** User must pack in Blender and copy again. |
| Mapping nodes | Import → user examines → if wrong: run bake, user examines → if correct: update scene refs, delete original, keep _gltf_ready |

---

## Commands

**Check:**
```bash
python3 tools/check_blend_asset.py assets/pet/<file>.blend
```

**Bake:**
```bash
# 1. Run bake
blender assets/pet/<file>.blend --background --python tools/bake_mapping_to_uvs.py

# 2. After user confirms _gltf_ready is correct:
#    - Update scene refs: change res://assets/pet/<file>.blend → res://assets/pet/<file>_gltf_ready.blend in any .tscn that uses it
#    - rm assets/pet/<file>.blend
#    - rm assets/pet/<file>.blend.import
#    - Keep <file>_gltf_ready.blend as the active asset (no rename)
```

---

## Folder convention

- `assets/pet/` — Active assets (Godot uses these). Only packed .blend and/or .glb.
