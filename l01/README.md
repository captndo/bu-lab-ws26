# Ultrasound sensor laboratory report

The report covers Exercises 1 and 2. All tables and plots use the same ten reference
measurements at 10, 20, 25, 30, 40, 50, 75, 100, 150, and 200 cm.

## Canonical sources

- `data/measurements.csv`: the single numerical source. Columns are `d` (cm),
  `v_multi` (mV), and `v_osc_max` (mV). The oscilloscope column is the current
  CH1 Max **Value**, not the statistics columns from the acquisition history.
- `data/osc/`: twelve distinct, lossless PNG acquisitions. The supplementary
  captures at 27 and 160 cm are included in the report but do not add rows to the
  ten-point reference measurement table. The 150 cm BMP was converted losslessly
  to PNG, with decoded-pixel equality checked before removing the BMP.
- `data/images/`: one copy of each distinct setup/reference-signal image.
  `setup_annotated.jpeg` is the annotated version of `setup.jpeg`.
- `docs/`: the supplied instructions, sensor datasheet, and temperature note.
- `report/lab01.typ` and `report/references.bib`: report content and references.
  `report/main.typ` includes `lab01.typ`. The common style is imported from
  `../shared/template.typ` at the repository level.

## Build

Use the shared launcher in the parent repository folder. On Windows, install
Python once as described in the repository README, then run:

```powershell
..\build.cmd l01
```

From the repository folder, `build.cmd --all` builds all available labs and
`build.cmd l01` builds only this report. The launcher manages the shared Python
environment automatically.

On Linux or macOS, from the repository folder:

```sh
.venv/bin/python build.py l01
```

The report is written to `../compiled-reports/lab01.pdf` at the repository level.
The Python `typst` package supplies the compiler automatically. The shared builder
runs `src/prepare.py` to regenerate plots and the capture index before compiling.
The previous `python src/build.py` command also delegates to the shared builder.
All scripts resolve their paths from their own location.

For plotting alone, from this lab folder, use an interpreter with the shared
requirements installed:

```sh
python src/ploter.py --input data/measurements.csv --output plots
```

The report appendix includes the complete numerical input and the actual analysis
script so readers can reproduce the analysis independently of the repository.

## Generated assets

All four vector figures are written to `plots/`, exactly where the report reads
its figures: `expectation_plot.svg`, `multimeter_plot.svg`, `osc_plot.svg`, and
`multimeter_error_plot.svg`. `plots/osc_captures.json` is the generated capture
index. Existing generated outputs are overwritten on each build.

The error figure contains voltage error above distance error. These are signed
errors (measured minus expected), while the appendix tables report absolute
deviations. Distance conversion/error is evaluated only for reference distances
of at least 25 cm. Expected voltages assume a nominal 5 V supply and the specified
25 cm minimum reported distance. Individual point annotations are omitted.

The acquisitions at 50 and 200 cm appear in Exercise 2; the other ten sensor-output
captures appear in the appendix. Each capture is included once, with its reference
distance in the caption.
