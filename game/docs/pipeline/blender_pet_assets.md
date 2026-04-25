# Blender Pet Assets (.blend in Godot)

Using **.blend files directly in Godot** (no manual glTF export): one rule for assets, and how to see animations.

---

## Rule: Pack before you copy

**Before copying a .blend into the project, pack all external resources into it.**

In Blender: **File → External Data → Pack Resources** (or “Pack All into .blend”).

**If the model uses Mapping nodes** (e.g. for texture position/rotation): run the bake script first:
```bash
blender path/to/model.blend --background --python tools/bake_mapping_to_uvs.py
```
Use the resulting `*_gltf_ready.blend` for the project (or export it to .glb).

Then the .blend is self-contained. Copy **only** the .blend into `assets/pet/`. No textures, no path fixes, no extra files. If you didn’t pack, fix it in Blender and save, then copy the .blend again.

**So Godot uses the packed textures (no external PNGs):**

1. In the FileSystem, select the `.blend` → in the Import dock set **Blender → Materials → Unpack Enabled** to **off**, then **Reimport**.
2. After import, open the same `.blend` (double‑click) → go to the **Materials** tab. For each material that uses a packed texture (e.g. **FaceTexture**), set **Use External → Enabled** to **off**. That makes Godot use the embedded texture from the import instead of looking for an external PNG. Click **Reimport** again to apply.

You do not need an `assets/pet/textures/` folder.

---

## Seeing your Blender animations in Godot

Double‑clicking a `.blend` in the FileSystem opens the **Import** preview (rotate the model only; no animation there). The animations are in the **imported scene**.

1. Open the **imported scene** (e.g. right‑click `JimmyFish.blend` → **Open in Editor**, or open the scene under `.godot/imported/`).
2. In the **Animation** panel at the bottom, use the **AnimationPlayer** and press **Play** on your Blender actions.

Or instance the pet in a test scene and run the game (F5) to see animations there.

If animations are missing or cut short: **Reimport** the .blend and check **Blender → Animation → Limit Playback** in the Import dock (disable or set a larger frame range if needed).

---

## Texture in wrong position or rotation (UV / mapping)

If the texture image is correct but appears shifted, rotated, or stretched on the model in Godot compared to Blender:

1. **Mapping node:** glTF does not support Blender's Mapping node. Run the bake script before copying:
   ```bash
   blender path/to/model.blend --background --python tools/bake_mapping_to_uvs.py
   ```
   Use the resulting `*_gltf_ready.blend` for the project. See `tools/README.md`.
2. **Disable Generate LOD** on the .blend import: select the `.blend` in FileSystem → Import dock → **Meshes → Generate LOD** off → **Reimport**. LOD generation has been reported to distort UVs on some Blender imports.
3. **Single UV map in Blender:** Godot’s glTF importer uses the **first** UV map for all materials. If your mesh has multiple UV maps (e.g. one for body, one for face), the face material may be using the wrong one in Godot. In Blender, either use only one UV map for the whole mesh, or make sure the face material uses the **first** UV map in the list.

---

## Quick reference

| Goal | Action |
|------|--------|
| Bring a pet into the project | In Blender: **Pack Resources**. If Mapping nodes: run `tools/bake_mapping_to_uvs.py`, use `*_gltf_ready.blend`. Copy .blend to `assets/pet/`. In Godot: **Blender → Materials → Unpack Enabled** off, **Reimport**. |
| See animation from .blend | Open the **imported scene** (not the Import preview), use **Animation** panel and Play. |
