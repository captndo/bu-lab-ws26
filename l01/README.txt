Lab N1 revision files. Merge these folders into your lab folder (the one that already has report/, data/, plots/):

  report/report_rev1.typ              new report source (original is NOT overwritten)
  data/osc_estimates.csv              estimated scope mean/min (from screenshots)
  data/images/*_annotated.png         annotated Fig. 2 pair and Fig. 6
  data/osc/annotated/*.png            five annotated scope screenshots
  plots/osc_stats_plot.svg            new characteristic plot

Compile from the repo root (the template lives in ../../shared, so --root is needed):
  typst compile --root . <lab folder>/report/report_rev1.typ

Search the .typ file for "TODO" (2 items to confirm with the lab partner).
