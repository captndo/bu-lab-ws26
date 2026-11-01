# Laboratory reports

Each lab has its own content, data, and generated figures. The report design lives
once in `shared/template.typ`. The root builder discovers folders named `l01`,
`l02`, etc. that contain `report/main.typ`.

## Windows: first use

1. Install [Python 3.10 or later](https://www.python.org/downloads/windows/).
2. Double-click `build.cmd` to build every available report. On first use, it
   creates `.venv` and installs the Python requirements; that step needs internet
   access. There is no need to activate the environment yourself. When opened
   without arguments, the window stays open so the result or error can be read.

From PowerShell in this folder:

```powershell
.\build.cmd l01          # One report
.\build.cmd l01 l02      # Selected reports
.\build.cmd --all        # All reports (also the default)
.\build.cmd --list       # Available labs
```

The launcher can also be run by its full path from another folder. Paths with
spaces are supported. The Python `typst` package includes the compiler; a separate
Typst installation is unnecessary. Once the Python requirements are installed,
these reports can be built without downloading anything further.

## Linux or macOS

Install Python 3.10+, then:

```sh
python3 -m venv .venv
.venv/bin/python -m pip install -r requirements.txt
.venv/bin/python build.py l01
.venv/bin/python build.py --all
```

`build.py` is cross-platform and uses whichever Python interpreter launched it.
Use an interpreter with the Python requirements installed. Commands work from any
working directory when `build.py` is addressed by its full path.

## Build behavior

For each selected lab, the builder:

1. Runs `src/prepare.py` if that file exists, using the same Python interpreter.
   Each lab owns its data processing; it should resolve paths from `__file__`.
2. Compiles `report/main.typ` with the Python `typst` package, using the repository
   folder as the Typst root so reports can import the shared template and assets.
3. Saves all PDFs in the root `compiled-reports/` folder: `l01` produces
   `compiled-reports/lab01.pdf`, `l02` produces `compiled-reports/lab02.pdf`, and so on.
   The folder is created automatically.

Preparation or compilation errors produce a nonzero exit status. An all-labs
build continues with the other labs and lists any failures at the end.

The existing `l01/src/build.py` command remains available as a compatibility
wrapper for building only `l01`.

## Adding another lab

Create `l02/report/main.typ` (or the corresponding next lab folder). It is
recognized automatically; no central list needs updating. A minimal report is:

```typst
#import "../../shared/template.typ": *

#show: lab-report.with(
  title: "Title of the next laboratory report",
  lab-id: "Lab N2",
  course: "BUL — WS26",
  author: "Author name",
  student-id: "Student ID",
  instructor: "Instructor name",
  date: "2026-11-01",
)

= Introduction
Report content goes here.
```

For reports split into multiple files, `report/main.typ` may include the main
content file, as in `l01`. If plots or other assets must be generated, add the
lab-specific preparation step in `l02/src/prepare.py`. Dependencies shared by
preparation scripts belong in the root `requirements.txt`.

The figure helper takes rendered content, so paths are resolved in the lab:

```typst
#report-figure(
  image("../plots/example.svg", width: 100%),
  [Caption for the figure.],
) <fig:example>
```

Keep measurements and assets inside their lab folder. Change the shared template
when a styling change should apply to every report; do not copy it into new labs.
