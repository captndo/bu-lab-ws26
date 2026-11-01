"""Build one or more lab reports, or all discovered lab folders."""

import argparse
from pathlib import Path
import re
import subprocess
import sys

REPO_ROOT = Path(__file__).resolve().parent


def discover_labs():
    return {
        path.name: path
        for path in sorted(
            REPO_ROOT.iterdir(),
            key=lambda path: (
                int(path.name[1:]) if re.fullmatch(r"l\d+", path.name) else -1,
                path.name,
            ),
        )
        if path.is_dir()
        and re.fullmatch(r"l\d+", path.name)
        and (path / "report" / "main.typ").is_file()
    }


def build_lab(lab, typst):
    prepare = lab / "src" / "prepare.py"
    if prepare.is_file():
        print(f"[{lab.name}] Preparing data and figures...", flush=True)
        subprocess.run([sys.executable, str(prepare)], cwd=lab, check=True)
    output = REPO_ROOT / "compiled-reports" / f"lab{lab.name[1:]}.pdf"
    output.parent.mkdir(parents=True, exist_ok=True)
    print(f"[{lab.name}] Compiling report...", flush=True)
    typst.compile(
        str(lab / "report" / "main.typ"),
        output=str(output),
        root=str(REPO_ROOT),
    )
    return output


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("labs", nargs="*", help="Lab folder names, e.g. l01 l02")
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--all", action="store_true", help="Build every lab (default)")
    mode.add_argument("--list", action="store_true", help="List available labs")
    args = parser.parse_args(argv)
    if sys.version_info < (3, 10):
        parser.error("Python 3.10 or later is required.")
    if args.labs and (args.all or args.list):
        parser.error("Use lab names, --all, or --list separately.")
    labs = discover_labs()
    if args.list:
        print("\n".join(labs) if labs else "No lab reports found.")
        return 0
    if not labs:
        parser.error("No lab folders containing report/main.typ were found.")
    selected = list(dict.fromkeys(args.labs)) if args.labs else list(labs)
    unknown = [name for name in selected if name not in labs]
    if unknown:
        parser.error(
            f"Unknown or incomplete lab: {', '.join(unknown)}. "
            f"Available: {', '.join(labs)}"
        )
    try:
        import typst
    except ImportError:
        print(
            "The Python typst package is missing. Run the Windows build.cmd "
            "launcher, or install the repository requirements with "
            "python -m pip install -r requirements.txt.",
            file=sys.stderr,
        )
        return 1
    successes, failures = [], []
    for name in selected:
        try:
            successes.append(build_lab(labs[name], typst))
        except (OSError, subprocess.CalledProcessError, typst.TypstError) as error:
            print(f"[{name}] FAILED: {error}", file=sys.stderr, flush=True)
            failures.append(name)
    print(f"\nBuilt {len(successes)} of {len(selected)} report(s).")
    for output in successes:
        print(output.relative_to(REPO_ROOT))
    if failures:
        print("Failed: " + ", ".join(failures), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
