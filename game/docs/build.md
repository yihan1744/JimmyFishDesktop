# Building the Desktop Pet

To share the app with others, you must **export** it as a standalone executable. Running from the Godot editor (F5) launches a debug window; the exported build is the real app.

---

## Prerequisites

1. **Export templates** — In Godot: **Editor → Manage Export Templates**. Download and install templates for your Godot version.
2. **Platform** — Export Windows builds from Windows, macOS builds from macOS (or use CI for cross-platform).

---

## Export output location

The Godot project root is the **`game/`** folder, but **presets write builds one level up** at **`../builds/`** (sibling to `game/`, usually the repository root’s `builds/`). That keeps the zippable `game/` tree free of build artifacts while exports stay in a fixed place next to the repo.

## Export Steps

1. Open the project in Godot (**`game/`** is the project folder; it contains `project.godot`).
2. Go to **Project → Export**.
3. Select a preset (defaults in `export_presets.cfg`):
   - **Windows Desktop** → e.g. `../builds/win/JimmyFishDesktop.exe` (and `JimmyFishDesktop.pck` if PCK is separate)
   - **macOS** → e.g. `../builds/mac/JimmyFishDesktop.app`
4. Click **Export Project** and choose the output path (or use the preset’s default).
5. The **`builds/`** folder next to `game/` will contain the executable and `.pck` as configured.

---

## Sharing

**Windows:** Zip the build output (or at least `JimmyFishDesktop.exe` and `JimmyFishDesktop.pck` if used). Recipients run `JimmyFishDesktop.exe`.

**macOS:** Zip `JimmyFishDesktop.app`. Recipients double-click the app. They may need to right-click → Open the first time if Gatekeeper blocks it.

---

## Command Line

```bash
# From a shell, with cwd = this project folder (where project.godot lives, i.e. game/):
# macOS
godot --path . --export-release "macOS" ../builds/mac/JimmyFishDesktop.app

# Windows (run from Windows)
godot --path . --export-release "Windows Desktop" ../builds/win/JimmyFishDesktop.exe
```

---

## Troubleshooting

- **"Export templates missing"** — Editor → Manage Export Templates → Download and Install.
- **"The app is damaged" (macOS)** — Right-click → Open, or adjust Gatekeeper settings.
- **Antivirus flags .exe** — Common with unsigned Windows builds. Consider code signing for distribution.
