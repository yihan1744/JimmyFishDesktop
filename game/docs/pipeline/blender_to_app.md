# Blender → Desktop Pet Pipeline

This pipeline is for **modelling and animation in Blender** and using the result in the desktop pet app on **Windows and macOS**. The app is Godot-based; Blender exports **glTF 2.0**, which Godot imports natively.

---

## Overview

1. **Blender**: Model and animate the pet (skeletal or shape keys).
2. **Export**: glTF 2.0 (`.glb` recommended for single file).
3. **Godot**: Place in `assets/`; import runs automatically. Use as scene or animation library.

---

## Blender Setup (Cross-Platform)

- Use the same Blender version on Windows and Mac to avoid export differences (e.g. 4.x LTS).
- Keep scale consistent: **1 Blender unit = 1 Godot unit** (no scale factor needed if you use default).
- Prefer **Y-up** in Blender (default); Godot 3D is Y-up.

---

## Modelling

- **Single mesh or rigged character**: both work. For a pet that moves, a simple armature is usually best.
- **Origin**: Place object origin where the “anchor” of the pet should be (e.g. feet or centre). Easiest for positioning on the desktop.
- **Poly count**: Keep low for a lightweight desktop app; LOD not required for a single pet.

---

## Animation

- **Skeletal**: Create armature, skin mesh, animate in Blender. Export includes armature + actions.
- **Shape keys**: Supported in glTF; Godot can animate them via AnimationPlayer or code.
- **Naming**: Use clear action names (e.g. `idle`, `walk`, `sleep`); they become Godot animation names.

---

## Export from Blender (glTF 2.0)

**If the model uses Mapping nodes:** run the bake script first so texture position/rotation is correct:
```bash
blender path/to/model.blend --background --python tools/bake_mapping_to_uvs.py
```
Use the resulting `*_gltf_ready.blend` for export.

1. **File → Export → glTF 2.0 (.glb/.gltf)**.
2. **Recommended settings** (works on both Windows and Mac):
   - **Format**: glTF Binary (`.glb`) for one file, or glTF Separate (`.gltf` + `.bin` + textures) if you prefer separate assets.
   - **Include**: Selected Objects or Visible Objects (depending on what the pet scene contains).
   - **Transform**: +Y Up (default).
   - **Geometry**: Apply Modifiers; optionally UVs, Normals, Tangents.
   - **Animation**: Export all actions or only selected; **Limit to Playback Range** if you want to trim.
   - **Shape Keys**: Enable if you use morph targets.
3. Export into the project’s **`assets/`** folder (e.g. `assets/pet/character.glb`).

---

## Godot Import

- Godot 4 imports `.glb`/`.gltf` automatically when placed under the project.
- **Recommended layout**: e.g. `assets/pet/character.glb` → use as:
  - **Packed scene**: Instance the whole pet in your main scene.
  - **AnimationLibrary**: If you need to share animations, re-export from the imported scene as an `AnimationLibrary` resource and use from an AnimationPlayer.
- **Materials**: glTF materials become StandardMaterial3D; adjust in Godot if needed (e.g. toon, transparency).
- **Skeleton**: Use the generated Skeleton3D; play animations via AnimationPlayer on the imported scene.

---

## Asset management and folder convention

All pet-related assets live under **`assets/pet/`** (same path on Windows and Mac so Godot references stay valid).

**Source assets (Blender):**

- Keep **`.blend`** source files in `assets/pet/` next to their exports.
- Use a consistent base name: e.g. `JimmyFish.blend` → export to `JimmyFish.glb` in the same folder.
- Godot 4 can import `.blend` directly (it converts via glTF under the hood). **If you use .blend in Godot, pack all external data in Blender first** (File → External Data → Pack Resources), then copy only the .blend—see **blender_pet_assets.md**. For the recommended pipeline, export **glTF 2.0** from Blender and place the **`.glb`** in `assets/pet/`; the `.blend` remains the source to edit.
- **Git tracking:** You do **not** need to track `.blend` files for the app to run—Godot uses the exported `.glb`/`.gltf`. Commit the `.glb` (and optionally `.blend` for source history). If you do track `.blend` files, use **Git LFS** so the repo stays small and pushes do not hit size limits.

**Runtime assets (Godot):**

- **`.glb`** / **`.gltf`**: exported from Blender; Godot imports these automatically.
- **`.blend`**: optional; Godot can import as scene; use for quick iteration or keep as source-only and commit the `.glb` for builds.
- **`*.import`**: Godot-generated; commit or add to `.gitignore` per team preference.

**Test assets:**

- Test models (e.g. **JimmyFish**) follow the same layout: `assets/pet/JimmyFish.blend` and, when exported, `assets/pet/JimmyFish.glb`.
- Do not place Blender or exported assets in the project root; keep them under `assets/pet/`.

**Example layout:**

```
assets/
  pet/
    JimmyFish.blend       # Test asset source (Blender)
    JimmyFish.blend.import # Godot import config (if using .blend in Godot)
    JimmyFish.glb         # Exported runtime asset (optional; from Blender glTF export)
    character.glb         # Another pet; same pattern
```

---

## Checklist (Before Commit)

- [ ] Blender sources (`.blend`) and exports (`.glb`/`.gltf`) live under `assets/pet/`, not project root.
- [ ] Exported as glTF 2.0 from Blender when using the recommended .glb pipeline.
- [ ] Test assets (e.g. JimmyFish) use the same folder and naming convention.
- [ ] Pet runs in Godot on your OS; test on the other OS if possible (Windows/Mac).
- [ ] No absolute or OS-specific paths in Godot scene references.
