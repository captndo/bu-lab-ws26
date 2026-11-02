#import "../../shared/template.typ": *

#show: lab-report.with(
  title: "Function and Characteristics of an Ultrasound Distance Sensor",
  lab-id: "Lab N1",
  course: "BUL — WS26",
  authors: (
    (name: "Hesandi Samarathunga", id: "2756611"),
    (name: "Stilian Dimitrov", id: "2914332"),
  ),
  instructor: "Prof. Dr. Rasmus Rettig",
  date: "2026-11-01",
)

// The report and plotting script consume the same three-column data source.
#let measurement-csv = csv("../data/measurements.csv")
#let headers = measurement-csv.first()
#let column(name) = measurement-csv.slice(1).map(row =>
  float(row.at(headers.position(header => header == name))))
#let distances = column("d").map(value => int(value))
#let Vmulti = column("v_multi").map(value => value * 1e-3)
#let VoscMax = column("v_osc_max").map(value => value * 1e-3)
#let volts-per-cm = 5 / 2048
#let expected = distances.map(distance => calc.max(distance, 25) * volts-per-cm)
#let multi-errors = range(distances.len()).map(i => Vmulti.at(i) - expected.at(i))
#let osc-deviations = range(distances.len()).map(i => calc.abs(VoscMax.at(i) - expected.at(i)))
#let multi-deviations = multi-errors.map(error => calc.abs(error))
#let max-multi = calc.max(..multi-deviations)
#let max-multi-index = multi-deviations.position(value => value == max-multi)
#let max-osc = calc.max(..osc-deviations)
#let max-osc-index = osc-deviations.position(value => value == max-osc)
#let captures = json("../plots/osc_captures.json")
#let scope-capture(distance, width: 90%) = report-figure(
  image("../data/osc/" + str(distance) + "cm.png", width: width),
  [Sensor output acquisition at a reference distance of #distance cm.],
)

= Introduction

Ultrasonic time-of-flight measurements determine the distance between a sensor and a reflecting object from the travel time of a transmitted sound wave. The distance follows from the measured round-trip time and the speed of sound in air.

This report documents Exercises 1 and 2 of the laboratory session: the characterization of the analog output of the *MaxBotix XL-MaxSonar-AEL0 MB1360* using a multimeter and an oscilloscope. The measured characteristic is compared with the nominal relationship specified in the sensor datasheet @labinstructions @maxbotix.

= Required Equipment

#table(
  columns: (35%, 65%),
  inset: 5pt, stroke: 0.4pt + rgb("D4DEE6"), align: left,
  table.header([*Equipment*], [*Purpose*]),
  [Arduino Nano and breadboard], [Supply and electrical connections for the sensor.],
  [MaxBotix MB1360 sensor], [Ultrasonic distance measurement with an analog voltage output.],
  [Mini-USB cable and connecting leads], [Power supply and connections between the components.],
  [Multimeter], [Measurement of the sensor's DC output voltage.],
  [Oscilloscope and probe], [Observation of the sensor output voltage over time.],
  [Cardboard box], [Reflecting target.],
  [Tripod and sensor mount], [Support and positioning of the sensor.],
  [Ruler of at least 2 m], [Reference for positioning the target.],
)

= Experiment 1 — Sensor Setup and Multimeter Characteristic

== Objective

The objective was to determine the sensor's analog output characteristic using a multimeter and to compare the measured voltages with the specified characteristic.

== Setup

The sensor and Arduino breadboard were mounted on a tripod positioned at the edge of a table. A ruler was placed beneath the tripod, with its scale extending in the measurement direction. The analog output and ground terminals of the sensor were connected to the positive and negative multimeter probes, respectively. The Arduino supplied power to the sensor. @fig:connections shows the electrical connections, while @fig:setup-views shows the mounting and target arrangement.

#report-figure(image("../data/images/setup_annotated.jpeg", height: 25%), "Annotated sensor, supply, ground, and multimeter connections.", ) <fig:connections>

#figure(
  grid(
    columns: (1fr, 1fr), gutter: 7mm,
    image("../data/images/setup_profile.jpeg", width: 100%, height: 82mm, fit: "contain"),
    image("../data/images/setup_behind.jpeg", width: 100%, height: 82mm, fit: "contain"),
  ),
  caption: [Side and rear views of the tripod-mounted sensor, ruler, and target arrangement.],
) <fig:setup-views>

== Procedure

For each measurement, the desired reference distance was identified on the ruler and the target was positioned accordingly. After allowing the output to settle, the multimeter voltage was recorded. The ten reference distances were 10, 20, 25, 30, 40, 50, 75, 100, 150, and 200 cm. Their selection was intended to examine the close-range behavior, the transition to the nominal linear characteristic, and the response at larger distances.

== Expectation

#block(breakable: false)[
For the MB1360, the nominal analog scaling is $U_("cc") / 2048$ volts per centimetre. With a nominal supply voltage of 5 V, the slope is approximately 2.441 mV/cm. The minimum reported distance is 25 cm. Closer objects typically produce the output corresponding to this minimum, although reliable detection below the minimum reported distance is not guaranteed @maxbotix. The expected characteristic used in the analysis is therefore

$ U_("expected")(d) = (5 / 2048) max(d, 25), $

where $d$ is the reference distance in cm and $U_("expected")$ is expressed in V. The nominal close-range level is approximately 61.04 mV. This characteristic is shown in @fig:expected.

]

The datasheet also identifies near-field effects below approximately 50 cm that can reduce measurement accuracy. Measurements at larger distances were therefore expected to provide a closer approximation to the nominal distance-dependent characteristic @maxbotix.

#report-figure(image("../plots/expectation_plot.svg", width: 100%), "Expected output characteristic for a nominal 5 V supply and a minimum reported distance of 25 cm.") <fig:expected>

== Results

The measured and expected voltages are compared in @fig:multimeter. @tab:exercise1-multimeter lists all ten readings and the calculated deviations. The numerical input and complete Python analysis program are reproduced in @app:python.

#report-figure(image("../plots/multimeter_plot.svg", width: 100%), "Multimeter readings and the expected voltage characteristic at the ten reference distances.") <fig:multimeter>

#pagebreak(weak: true)

The signed voltage error at measurement point $i$ was calculated as

$ e_(U, i) = U_("multi", i) - U_("expected", i). $

Here, $U_("multi", i)$ is the recorded multimeter voltage and $U_("expected", i)$ is the expected voltage at reference distance $d_i$. Positive errors indicate readings above the expectation; negative errors indicate readings below it. The absolute voltage deviation is $Delta U_i = |e_(U, i)|$.

For reference distances of at least 25 cm, the indicated distance and its signed error were calculated using

$ d_("ind", i) = (2048 / 5) U_("multi", i), quad
  e_(d, i) = d_("ind", i) - d_i = (2048 / 5) e_(U, i). $

Voltages in these expressions are in V and distances are in cm. Distance conversion and distance error are not evaluated for the 10 cm and 20 cm reference points because these lie below the specified minimum reported distance. Their voltage deviations are still evaluated against the nominal 25 cm floor.

@fig:multi-errors shows the signed voltage and distance errors for 25–200 cm. The appendix table reports absolute deviations; its voltages and deviations were calculated before rounding the displayed values.

#report-figure(image("../plots/multimeter_error_plot.svg", width: 95%), "Signed multimeter voltage and distance errors for reference distances of 25–200 cm. The dashed line marks zero error; the diamond marks the largest absolute error.") <fig:multi-errors>

== Discussion

The ten measurement points were selected in three groups. Distances of 10, 20, and 25 cm examine the behavior at and below the minimum reported distance. Measurements at 30, 40, and 50 cm examine the near-field region described in the datasheet. Finally, 75, 100, 150, and 200 cm examine the nominal linear characteristic at larger distances.

The readings at 10 cm and 20 cm were 76 mV and 75 mV, respectively. Their similar values do not provide a useful distinction between these reference distances. At 25 cm and 30 cm, the calculated distance errors were approximately 4.90 cm and 3.59 cm. Between 40 cm and 100 cm, the errors ranged from approximately 1.37 cm to 2.43 cm. The errors at 150 cm and 200 cm were larger, at approximately 14.83 cm and 17.32 cm. Thus, agreement with the expected characteristic was strongest among the sampled points from 40 cm to 100 cm; these individual readings do not establish repeatability throughout that interval.

The nominal relationship also depends on supply voltage and ambient temperature. The output voltage is proportional to the supply voltage, but the supply was not measured simultaneously with the output. The analysis therefore assumes the nominal Arduino supply of 5 V rather than a measured supply value. In addition, the speed of sound changes by approximately 0.6 m/s per degree Celsius. The manufacturer provides a temperature-compensation expression, but no ambient-temperature measurements were recorded and this correction could not be applied @maxbotix @temperature.

The maximum absolute voltage deviation among the ten readings occurred at #distances.at(max-multi-index) cm and was #calc.round(max-multi * 1000, digits: 2) mV, corresponding to a distance error of #calc.round(max-multi / volts-per-cm, digits: 2) cm.

= Experiment 2 — Oscilloscope Characteristic

== Objective

The objective was to investigate the temporal behavior of the sensor output and to compare its minimum, mean, and maximum voltages with Experiment 1 and the sensor datasheet.

== Setup

The setup from Experiment 1 was retained, with the multimeter replaced by an oscilloscope probe connected between the analog output and ground terminals. @fig:osc-setup shows the oscilloscope and the sensor arrangement.

#report-figure(image("../data/images/setup_osc.jpeg", width: 100%), "Laboratory arrangement for observing the sensor output with the oscilloscope.") <fig:osc-setup>

== Procedure

The probe was set to 1× attenuation and its response was checked using the oscilloscope's built-in reference signal, shown in @fig:probe-check. This documents the reference-signal check rather than an independent calibration of the voltage scale.

#report-figure(image("../data/images/probe_calib.jpeg", width: 90%), "Oscilloscope display during the probe response check using the built-in reference signal.") <fig:probe-check>

Measurements were performed at the same ten reference distances as in Experiment 1. The intended procedure was to determine the minimum, mean, and maximum output voltages at each distance. During acquisition, however, only the maximum-voltage measurement was selected. The oscilloscope's statistical readouts were interpreted as the remaining required measurements. The horizontal timebase was 4 µs per division, with a sampling rate of 250 MS/s and a record length of 10,000 samples.

== Expectation

The output was expected to remain approximately constant while the target distance remained unchanged. When the target moved closer to or farther from the sensor, a transition of finite duration was expected before the output reached its new level.

== Results

@fig:osc-characteristic compares the recorded oscilloscope maxima with the expected characteristic and the multimeter readings. @tab:exercise2-oscilloscope lists the ten maxima, the expected voltages, and their absolute deviations.

For each measurement point $i$, the absolute voltage deviation was calculated as

$ Delta U_i = |U_("expected", i) - U_("osc,max", i)|. $

Here, $U_("expected", i)$ is the nominal voltage at reference distance $d_i$, and $U_("osc,max", i)$ is the maximum voltage recorded in the oscilloscope acquisition at that distance. The absolute value gives the magnitude of the difference irrespective of its sign. The expected voltages use the same nominal 5 V supply and 25 cm floor as Experiment 1. Values in @tab:exercise2-oscilloscope are expressed in mV and were calculated before rounding.

The largest absolute deviation among the recorded maxima was

$ Delta U_("max") = max_i (Delta U_i). $

It occurred at #distances.at(max-osc-index) cm: the expected voltage was #calc.round(expected.at(max-osc-index) * 1000, digits: 2) mV and the recorded maximum was #calc.round(VoscMax.at(max-osc-index) * 1000, digits: 2) mV, giving a deviation of #calc.round(max-osc * 1000, digits: 2) mV. This refers to the available acquisition windows and is not a maximum established over complete ranging cycles.

#report-figure(image("../plots/osc_plot.svg", width: 100%), "Recorded oscilloscope maxima, multimeter readings, and the expected characteristic at the ten reference distances.") <fig:osc-characteristic>

@fig:scope50 and @fig:scope200 reproduce representative acquisitions at 50 cm and 200 cm. The remaining captures appear in @app:scope. In the illustrated records, the output appears as a nearly horizontal trace with fast fluctuations. The CH1 Max *Value* entries are the maxima used in the characteristic curve.

#scope-capture(50) <fig:scope50>
#scope-capture(200) <fig:scope200>

== Discussion

Two procedural errors limit the interpretation of these measurements. First, the selected settings give an acquisition window of approximately 40 µs, compared with a sensor ranging cycle of approximately 99 ms @maxbotix. Each acquisition therefore covers only approximately $1 / 2500$ of a ranging cycle. The waveforms show local voltage levels and fast noise but do not establish the output behavior over a complete cycle.

Second, only the maximum output voltage was measured. In the selected CH1 Max row, *Value* gives the current acquisition's maximum. The *Mean*, *Min*, and *Max* columns instead describe statistics of maximum-voltage measurements across acquisitions; they are not separate waveform mean and minimum measurements @tektronix. The missing waveform mean and minimum cannot be reconstructed reliably from those statistics.

Between 25 cm and 100 cm, the oscilloscope maxima and multimeter readings show a broadly similar increasing characteristic. The maxima are consistently higher than the multimeter readings in this interval. This may partly reflect the different measurement quantities: a maximum over a short acquisition window and a DC voltage reading.

The recorded maxima provide the clearest distance-dependent response among the sampled points from approximately 50 cm to 100 cm. At 150 cm and 200 cm, the recorded maximum remained at 280 mV despite the different target distances. These results indicate reduced agreement with the expected characteristic in this setup, rather than establishing an intrinsic upper range limit. Reflections from surrounding objects or the ground are a possible explanation, but the available data do not establish the cause conclusively.

Discussions during the laboratory session identified time variation over a ranging cycle as relevant to ADC measurements. This explanation is distinct from what the short acquisitions demonstrate. At 10 kHz, successive ADC samples are 100 µs apart, whereas each saved oscilloscope record spans only approximately 40 µs. These records therefore do not establish whether 10 kHz sampling adequately represents the complete output waveform. Short disturbances may be missed, and frequency components above the 5 kHz Nyquist limit can alias into the sampled signal unless sufficiently attenuated before conversion. The available captures do not quantify these effects.

= Conclusion

The analog output characteristic was assessed at ten reference distances using a multimeter and recorded oscilloscope maxima. The multimeter readings followed the expected characteristic most closely among the sampled points from 40 cm to 100 cm. Its largest absolute voltage deviation was #calc.round(max-multi * 1000, digits: 2) mV at #distances.at(max-multi-index) cm, equivalent to #calc.round(max-multi / volts-per-cm, digits: 2) cm. For the recorded oscilloscope maxima, the largest absolute deviation was #calc.round(max-osc * 1000, digits: 2) mV at #distances.at(max-osc-index) cm.

The characteristic comparison was therefore completed for the available measurements, while the temporal characterization remained incomplete. The oscilloscope records cover only short portions of a ranging cycle, and separate waveform mean and minimum measurements were not obtained. The results consequently support a qualified comparison of the recorded characteristics, but not a complete assessment of cycle-wide fluctuations or ADC sampling adequacy.

#pagebreak(weak: true)
#bibliography("references.bib", style: "ieee", title: [References])

#pagebreak()
= Appendix

== Supporting Tables

=== Experiment 1: Multimeter measurements and absolute deviations

For the 10 cm and 20 cm reference points, the expected voltage is the nominal 25 cm floor. Their indicated distances and distance deviations are not evaluated because the reference distances lie below the specified ranging region. A dash denotes these entries.

#figure(
  table(
    columns: (11%, 18%, 18%, 18%, 17%, 18%), align: right,
    inset: 4pt, stroke: 0.4pt + rgb("D4DEE6"),
    table.header([*$d$ (cm)*], [*$U_("expected")$ (mV)*], [*$U_("multi")$ (mV)*], [*$d_("ind")$ (cm)*], [*$Delta U$ (mV)*], [*$|e_d|$ (cm)*]),
    ..range(distances.len()).map(i => (
      [#distances.at(i)],
      [#calc.round(expected.at(i) * 1000, digits: 2)],
      [#calc.round(Vmulti.at(i) * 1000, digits: 2)],
      if distances.at(i) >= 25 { [#calc.round(Vmulti.at(i) / volts-per-cm, digits: 2)] } else { [—] },
      [#calc.round(multi-deviations.at(i) * 1000, digits: 2)],
      if distances.at(i) >= 25 { [#calc.round(multi-deviations.at(i) / volts-per-cm, digits: 2)] } else { [—] },
    )).flatten(),
  ),
  caption: [Multimeter readings, nominal expected voltages, and absolute voltage and distance deviations.],
) <tab:exercise1-multimeter>

=== Experiment 2: Oscilloscope maxima and absolute deviations

#figure(
  table(
    columns: (18%, 28%, 28%, 26%), align: right,
    inset: 4pt, stroke: 0.4pt + rgb("D4DEE6"),
    table.header([*$d$ (cm)*], [*$U_("expected")$ (mV)*], [*$U_("osc,max")$ (mV)*], [*$Delta U$ (mV)*]),
    ..range(distances.len()).map(i => (
      [#distances.at(i)],
      [#calc.round(expected.at(i) * 1000, digits: 2)],
      [#calc.round(VoscMax.at(i) * 1000, digits: 2)],
      [#calc.round(osc-deviations.at(i) * 1000, digits: 2)],
    )).flatten(),
  ),
  caption: [Recorded oscilloscope maxima, nominal expected voltages, and absolute voltage deviations.],
) <tab:exercise2-oscilloscope>

#pagebreak()
== Additional oscilloscope captures <app:scope>

The acquisitions at 50 cm and 200 cm appear in the main text. All other available sensor-output captures are reproduced here, including the supplementary captures at 27 cm and 160 cm. Each acquisition uses 4 µs/div, 250 MS/s, and 10,000 samples; CH1 uses 100 mV/div.

#let supplementary = captures.filter(capture => capture.distance != 50 and capture.distance != 200)
#for (index, capture) in supplementary.enumerate() {
  if index > 0 and calc.rem(index, 2) == 0 { pagebreak() }
  scope-capture(capture.distance, width: if index < 2 { 86% } else { 90% })
}

#pagebreak()
== Python analysis and numerical input <app:python>

The following input contains the ten reference measurements used in both experiments. The column `d` gives the reference distance in cm; `v_multi` gives the multimeter DC voltage in mV; and `v_osc_max` gives the CH1 Max Value recorded by the oscilloscope, also in mV.

#raw(read("../data/measurements.csv"), lang: "csv", block: true)

The program below converts the recorded voltages to V, calculates the expected characteristic for a nominal 5 V supply and a minimum reported distance of 25 cm, and evaluates the indicated distances, signed errors, and absolute deviations described in the report. It prints the calculated values and their maximum deviations and generates the four characteristic and error figures. Indicated distances and distance errors are evaluated only for reference distances of at least 25 cm; the printed output marks the remaining entries with a dash. No waveform mean or minimum is inferred from the recorded maxima.

The program requires Python 3.10 or later and Matplotlib 3.7 or later. To run it independently, save the input above as `measurements.csv` and the program below as `analysis.py` in the same folder, install Matplotlib, and run:

#raw("python -m pip install \"matplotlib>=3.7\"\npython analysis.py", lang: "sh", block: true)

The figures are saved as SVG files in a folder named `plots`. Alternative input and output locations may be supplied using the `--input` and `--output` command-line arguments.

#{
  set text(font: "DejaVu Sans Mono", size: 8pt)
  set par(justify: false, leading: 0.35em)
  raw(read("../src/ploter.py"), lang: "python", block: true)
}
