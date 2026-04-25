#!/usr/bin/env python3
"""
Run the Blender check on a .blend file and output human-readable feedback.

Usage: python3 tools/check_blend_asset.py assets/pet/<file>.blend

Or: blender assets/pet/<file>.blend --background --python tools/check_blend_file.py
    (outputs raw JSON)
"""
import json
import subprocess
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent


def main():
    if len(sys.argv) < 2:
        print("Usage: python3 tools/check_blend_asset.py <path-to-blend-file>")
        sys.exit(2)

    blend_path = Path(sys.argv[1])
    if not blend_path.exists():
        print(f"Error: File not found: {blend_path}")
        sys.exit(2)

    blend_path = blend_path.resolve()
    check_script = PROJECT_ROOT / "tools" / "check_blend_file.py"

    result = subprocess.run(
        ["blender", str(blend_path), "--background", "--python", str(check_script)],
        capture_output=True,
        text=True,
        cwd=PROJECT_ROOT,
    )
    stdout = result.stdout.strip()

    try:
        data = json.loads(stdout)
    except json.JSONDecodeError:
        print("Error: Could not parse check output.")
        if stdout:
            print(stdout)
        sys.exit(2)

    unpacked = data.get("unpacked", False)
    unpacked_names = data.get("unpacked_names", [])
    mapping_nodes = data.get("mapping_nodes", 0)

    if unpacked:
        print("RED FLAG: Unpacked resources detected.")
        if unpacked_names:
            print(f"  Unpacked: {', '.join(unpacked_names)}")
        print()
        print(
            "Cannot accept. User must pack in Blender (File → External Data → Pack Resources), "
            "save, then copy the .blend to assets/pet/ again."
        )
        sys.exit(1)

    if mapping_nodes > 0:
        print(
            f"WARNING: {mapping_nodes} Mapping node(s) found. glTF does not support Mapping nodes; "
            "texture position/rotation may be wrong in Godot."
        )
        print()
        print(
            "Workflow: Import in Godot → user examines. If texture is wrong, run bake "
            "(see docs/pipeline/blender_asset_incoming.md)."
        )
        sys.exit(0)

    print("OK: No unpacked resources, no Mapping nodes.")
    sys.exit(0)


if __name__ == "__main__":
    main()
