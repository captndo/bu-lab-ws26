"""Compatibility command: build this lab using the shared repository builder."""

from pathlib import Path
import subprocess
import sys

LAB_DIR = Path(__file__).resolve().parent.parent


def main():
    subprocess.run(
        [sys.executable, str(LAB_DIR.parent / "build.py"), LAB_DIR.name],
        check=True,
    )


if __name__ == "__main__":
    main()
