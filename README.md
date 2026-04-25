# JimmyFishDesktop

A small **desktop pet** built with [Godot](https://godotengine.org/). **Live build (web):** [yihan1744.github.io/JimmyFishDesktop](https://yihan1744.github.io/JimmyFishDesktop/)

## Source layout

| Part | Path | What it is |
|------|------|------------|
| **Frontend (web)** | **`docs/`** | GitHub Pages site: download / landing page (`index.html`, assets, packaged zips for the site). Publishes to the live URL above. |
| **Backend (app)** | **`game/`** | Godot project: `project.godot`, scenes, scripts, assets. Open **this folder** in the Godot editor. |
| **Backend (app)** | `builds/` | Desktop export output (sibling to `game/`; created from Godot). See `game/docs/build.md`. |

For run instructions, export steps, and the Blender → Godot pipeline, see **[`game/README.md`](game/README.md)** and the files in **`game/docs/`**.

