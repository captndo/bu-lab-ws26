"""Regenerate this lab's figures and oscilloscope capture index."""

import json
from pathlib import Path

from ploter import main as build_plots

LAB_DIR = Path(__file__).resolve().parent.parent


def main():
    build_plots(LAB_DIR / "data" / "measurements.csv", LAB_DIR / "plots")
    captures = []
    for path in (LAB_DIR / "data" / "osc").glob("*cm.png"):
        distance = int(path.stem.removesuffix("cm"))
        if distance <= 0:
            raise ValueError("Oscilloscope capture distances must be positive.")
        captures.append({"distance": distance, "file": path.name})
    captures.sort(key=lambda capture: capture["distance"])
    (LAB_DIR / "plots" / "osc_captures.json").write_text(
        json.dumps(captures, indent=2) + "\n", encoding="utf-8"
    )


if __name__ == "__main__":
    main()
