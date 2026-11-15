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
  date: "2026-11-15", // revised version; the first submission was dated 2026-11-01
)

// ============================================================================
// Data. The report and the plotting script consume the same three-column file.
// ============================================================================
#let measurement-csv = csv("../data/measurements.csv")
#let headers = measurement-csv.first()
#let column(name) = measurement-csv.slice(1).map(row =>
  float(row.at(headers.position(header => header == name))))
#let distances = column("d").map(value => int(value))
#let Vmulti = column("v_multi").map(value => value * 1e-3)
#let VoscMax = column("v_osc_max").map(value => value * 1e-3)
#let volts-per-cm = 5 / 2048
#let expected = distances.map(distance => calc.max(distance, 25) * volts-per-cm)
#let n = distances.len()
#let multi-errors = range(n).map(i => Vmulti.at(i) - expected.at(i))
#let osc-deviations = range(n).map(i => calc.abs(VoscMax.at(i) - expected.at(i)))
#let multi-deviations = multi-errors.map(error => calc.abs(error))
#let max-multi = calc.max(..multi-deviations)
#let max-multi-index = multi-deviations.position(value => value == max-multi)
#let max-osc = calc.max(..osc-deviations)
#let max-osc-index = osc-deviations.position(value => value == max-osc)
#let captures = json("../plots/osc_captures.json")

// New: oscilloscope mean and minimum, estimated from the saved screenshots
// (see Section "Estimation of minimum and mean"). Same distances as above.
#let estimate-csv = csv("../data/osc_estimates.csv")
#let estimate-column(name) = {
  let head = estimate-csv.first()
  let k = head.position(header => header == name)
  estimate-csv.slice(1).map(row => float(row.at(k)))
}
#assert(
  estimate-column("d").map(value => int(value)) == distances,
  message: "osc_estimates.csv must list the same distances as measurements.csv",
)
#let VoscMean = estimate-column("v_osc_mean").map(value => value * 1e-3)
#let VoscMin = estimate-column("v_osc_min").map(value => value * 1e-3)

// ----------------------------------------------------------------------------
// Derived quantities (all numbers quoted in the text come from here)
// ----------------------------------------------------------------------------
#let at-d(values, distance) = values.at(distances.position(x => x == distance))
#let mv(value) = calc.round(value * 1000, digits: 0)
#let idx-between(lo, hi) = range(n).filter(i => distances.at(i) >= lo and distances.at(i) <= hi)
#let mean-deviations = range(n).map(i => calc.abs(VoscMean.at(i) - expected.at(i)))
#let max-mean = calc.max(..mean-deviations)
#let max-mean-index = mean-deviations.position(value => value == max-mean)

// usable range 40 ... 100 cm
#let usable = idx-between(40, 100)
#let max-usable = calc.max(..usable.map(i => multi-deviations.at(i)))
#let max-usable-index = usable.find(i => multi-deviations.at(i) == max-usable)
#let max-usable-mean = calc.max(..usable.map(i => mean-deviations.at(i)))

#let linfit(xs, ys) = {
  let m = xs.len()
  let sx = xs.sum()
  let sy = ys.sum()
  let sxy = range(m).map(i => xs.at(i) * ys.at(i)).sum()
  let sxx = xs.map(x => x * x).sum()
  let slope = (m * sxy - sx * sy) / (m * sxx - sx * sx)
  (slope, (sy - slope * sx) / m)
}
#let fit = linfit(usable.map(i => float(distances.at(i))), usable.map(i => Vmulti.at(i)))
#let fit-slope = fit.at(0) * 1000   // mV/cm
#let fit-offset = fit.at(1) * 1000  // mV
#let nominal-slope = volts-per-cm * 1000
#let slope-change = (fit-slope / nominal-slope - 1) * 100

#let floor-idx = idx-between(10, 25)
#let floor-multi = floor-idx.map(i => Vmulti.at(i))
#let floor-mean = floor-idx.map(i => VoscMean.at(i))
#let mean-vs-multi = idx-between(10, 100).map(i => calc.abs(VoscMean.at(i) - Vmulti.at(i)))
#let max-mean-vs-multi = calc.max(..mean-vs-multi)

// width of the fast fluctuation: recorded maximum minus estimated minimum
#let span = range(n).map(i => (VoscMax.at(i) - VoscMin.at(i)) * 1000)
#let span-min = calc.round(calc.min(..span), digits: 0)
#let span-max = calc.round(calc.max(..span), digits: 0)
#let span-at(distance) = calc.round(at-d(VoscMax, distance) * 1000 - at-d(VoscMin, distance) * 1000, digits: 0)
#let cm-per-mv = 1 / (volts-per-cm * 1000)
#let adc-step = 5000 / 1024  // mV per step, 10-bit ADC with 5 V reference

// ----------------------------------------------------------------------------
// Figure helpers
// ----------------------------------------------------------------------------
#let scope-capture(distance, observation, width: 88%) = report-figure(
  image("../data/osc/annotated/" + str(distance) + "cm.png", width: width),
  [Oscilloscope acquisition at a reference distance of #distance cm. #observation],
)
#let scope-capture-plain(distance, width: 90%) = report-figure(
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
  [Multimeter (Rigol DM3051)], [Measurement of the sensor's DC output voltage.],
  [Oscilloscope (Tektronix MDO3034) and probe], [Observation of the sensor output voltage over time.],
  [Cardboard box], [Reflecting target.],
  [Tripod and sensor mount], [Support and positioning of the sensor.],
  [Ruler of at least 2 m], [Reference for positioning the target.],
)

= Experiment 1 — Sensor Setup and Multimeter Characteristic

== Objective

The objective was to determine the sensor's analog output characteristic using a multimeter and to compare the measured voltages with the specified characteristic.

== Setup

The sensor and Arduino breadboard were mounted on a tripod positioned at the edge of a table. A ruler was placed beneath the tripod, with its scale extending in the measurement direction. The cardboard box served as the reflecting target and was positioned manually at the reference distance. The distance $d$ is the distance between the sensor front and the cardboard, read on the ruler; @fig:setup-views shows the ruler, the measurement direction, and the target.

The analog output and ground terminals of the sensor were connected to the positive and negative multimeter probes, respectively. The Arduino supplied power to the sensor. @fig:connections shows the electrical connections.

#report-figure(image("../data/images/setup_annotated.jpeg", height: 25%), "Annotated sensor, supply, ground, and multimeter connections.", ) <fig:connections>

#figure(
  grid(
    columns: (1fr, 1fr), gutter: 7mm,
    image("../data/images/setup_profile_annotated.png", width: 100%, height: 110mm, fit: "contain"),
    image("../data/images/setup_behind_annotated.png", width: 100%, height: 110mm, fit: "contain"),
  ),
  caption: [Side view (left) and rear view (right) of the tripod-mounted sensor. The ruler lies along the measurement direction. The distance $d$ is measured from the sensor front to the cardboard target and read on the ruler.],
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

The measured and expected voltages are compared in @fig:multimeter. @tab:exercise1-multimeter lists all ten readings and the calculated deviations.

#report-figure(image("../plots/multimeter_plot.svg", width: 100%), "Multimeter readings and the expected voltage characteristic at the ten reference distances.") <fig:multimeter>

#pagebreak(weak: true)

The signed voltage error at measurement point $i$ was calculated as

$ e_(U, i) = U_("multi", i) - U_("expected", i). $

Here, $U_("multi", i)$ is the recorded multimeter voltage and $U_("expected", i)$ is the expected voltage at reference distance $d_i$. Positive errors indicate readings above the expectation; negative errors indicate readings below it. The absolute voltage deviation is $Delta U_i = |e_(U, i)|$.

For reference distances of at least 25 cm, the indicated distance and its signed error were calculated using

$ d_("ind", i) = (2048 / 5) U_("multi", i), quad
  e_(d, i) = d_("ind", i) - d_i = (2048 / 5) e_(U, i). $

Voltages in these expressions are in V and distances are in cm. Distance conversion and distance error are not evaluated for the 10 cm and 20 cm reference points because these lie below the specified minimum reported distance. Their voltage deviations are still evaluated against the nominal 25 cm floor. Voltages and deviations in @tab:exercise1-multimeter were calculated before rounding the displayed values.

#figure(
  table(
    columns: (11%, 18%, 18%, 18%, 17%, 18%), align: right,
    inset: 4pt, stroke: 0.4pt + rgb("D4DEE6"),
    table.header([*$d$ (cm)*], [*$U_("expected")$ (mV)*], [*$U_("multi")$ (mV)*], [*$d_("ind")$ (cm)*], [*$Delta U$ (mV)*], [*$|e_d|$ (cm)*]),
    ..range(n).map(i => (
      [#distances.at(i)],
      [#calc.round(expected.at(i) * 1000, digits: 2)],
      [#calc.round(Vmulti.at(i) * 1000, digits: 2)],
      if distances.at(i) >= 25 { [#calc.round(Vmulti.at(i) / volts-per-cm, digits: 2)] } else { [—] },
      [#calc.round(multi-deviations.at(i) * 1000, digits: 2)],
      if distances.at(i) >= 25 { [#calc.round(multi-deviations.at(i) / volts-per-cm, digits: 2)] } else { [—] },
    )).flatten(),
  ),
  caption: [Multimeter readings, nominal expected voltages, and absolute voltage and distance deviations. A dash denotes entries that are not evaluated because the reference distance lies below the specified minimum reported distance.],
) <tab:exercise1-multimeter>

@fig:multi-errors shows the signed voltage and distance errors for 25–200 cm.

#report-figure(image("../plots/multimeter_error_plot.svg", width: 95%), "Signed multimeter voltage and distance errors for reference distances of 25–200 cm. The dashed line marks zero error; the diamond marks the largest absolute error.") <fig:multi-errors>

== Assessment

*Q1 – Why were these distances selected?* The distances are not equally spaced. They were chosen to resolve the features of the characteristic. The distances 10, 20, and 25 cm lie at and below the minimum reported distance and show the flat floor. The distances 30, 40, and 50 cm cover the near-field region, where the datasheet reports reduced accuracy. The distances 75, 100, 150, and 200 cm cover the linear region up to the 2 m that the ruler allowed. More points were placed where the characteristic changes (25 to 50 cm) than where it is linear.

*Q2 – In which distance range is the output usable?* The output is usable between 40 cm and 100 cm. In this range the distance error was at most #calc.round(max-usable / volts-per-cm, digits: 2) cm (#calc.round(max-usable * 1000, digits: 2) mV at #distances.at(max-usable-index) cm). At 25 cm and 30 cm the readings can be used with a positive offset of #calc.round(at-d(multi-errors, 25) / volts-per-cm, digits: 2) cm and #calc.round(at-d(multi-errors, 30) / volts-per-cm, digits: 2) cm. At and below 25 cm the output stays between #calc.round(calc.min(..floor-multi) * 1000, digits: 0) mV and #calc.round(calc.max(..floor-multi) * 1000, digits: 0) mV (10 cm: #mv(at-d(Vmulti, 10)) mV, 20 cm: #mv(at-d(Vmulti, 20)) mV) and carries no distance information. Above 100 cm the readings fall below the expected values by #calc.round(calc.abs(at-d(multi-errors, 150)) / volts-per-cm, digits: 2) cm (150 cm) and #calc.round(calc.abs(at-d(multi-errors, 200)) / volts-per-cm, digits: 2) cm (200 cm). Each distance was measured once, so repeatability is not established.

*Q3 – How well does the characteristic fit the datasheet curve?* The shape agrees: a flat floor at the minimum reported distance and a linear rise above it. The slope is lower than nominal. A linear fit to the multimeter readings from 40 cm to 100 cm gives #calc.round(fit-slope, digits: 2) mV/cm instead of #calc.round(nominal-slope, digits: 3) mV/cm (#calc.round(slope-change, digits: 1) %), with an offset of #calc.round(fit-offset, digits: 1) mV. The floor level is #calc.round(calc.min(..floor-multi) * 1000, digits: 0) to #calc.round(calc.max(..floor-multi) * 1000, digits: 0) mV instead of the nominal 61.04 mV. Above 100 cm the readings fall below the nominal line.

*Q4 – What is the maximum deviation?* The largest deviation among the ten readings occurred at #distances.at(max-multi-index) cm and was #calc.round(max-multi * 1000, digits: 2) mV, corresponding to a distance error of #calc.round(max-multi / volts-per-cm, digits: 2) cm (#calc.round(max-multi / volts-per-cm / distances.at(max-multi-index) * 100, digits: 1) % of the distance). Within the usable range of 40 cm to 100 cm, the largest deviation was #calc.round(max-usable * 1000, digits: 2) mV at #distances.at(max-usable-index) cm, corresponding to #calc.round(max-usable / volts-per-cm, digits: 2) cm.

*Further influences.* The nominal relationship also depends on supply voltage and ambient temperature. The output voltage is proportional to the supply voltage, but the supply was not measured simultaneously with the output. The analysis therefore assumes the nominal Arduino supply of 5 V rather than a measured supply value. In addition, the speed of sound changes by approximately 0.6 m/s per degree Celsius. The manufacturer provides a temperature-compensation expression, but no ambient-temperature measurements were recorded and this correction could not be applied @maxbotix @temperature.

= Experiment 2 — Oscilloscope Characteristic

== Objective

The objective was to investigate the temporal behavior of the sensor output and to compare its minimum, mean, and maximum voltages with Experiment 1 and the sensor datasheet.

== Setup

The setup from Experiment 1 was retained, with the multimeter replaced by an oscilloscope probe connected between the analog output and ground terminals. @tab:connections lists the connections and @fig:osc-setup shows the oscilloscope and the sensor arrangement.

// TODO (check with lab partner): confirm that the probe ground clip was on the sensor GND / Arduino GND.
#figure(
  table(
    columns: (30%, 70%),
    inset: 5pt, stroke: 0.4pt + rgb("D4DEE6"), align: left,
    table.header([*Sensor pin*], [*Connected to*]),
    [V+ (supply)], [Arduino 5 V supply],
    [GND], [Arduino GND and oscilloscope probe ground clip],
    [Uout (analog output)], [Oscilloscope probe tip (channel CH1)],
  ),
  caption: [Connections of the sensor in Experiment 2.],
) <tab:connections>

#report-figure(image("../data/images/setup_osc_annotated.png", width: 100%), "Laboratory arrangement for observing the sensor output with the oscilloscope. The probe on CH1 is connected to the sensor output (Uout) and ground (GND).") <fig:osc-setup>

== Procedure

The probe was set to 1× attenuation and its response was checked using the oscilloscope's built-in reference signal, shown in @fig:probe-check. This documents the reference-signal check rather than an independent calibration of the voltage scale.

#report-figure(image("../data/images/probe_calib.jpeg", width: 90%), "Oscilloscope display during the probe response check using the built-in reference signal.") <fig:probe-check>

Measurements were performed at the same ten reference distances as in Experiment 1. @tab:scope-settings lists the oscilloscope settings visible in the screenshots. A second measurement row for CH2 is displayed in the screenshots; CH2 is not used in the evaluation.

#figure(
  table(
    columns: (30%, 70%),
    inset: 5pt, stroke: 0.4pt + rgb("D4DEE6"), align: left,
    table.header([*Setting*], [*Value*]),
    [Vertical scale (CH1)], [100 mV/div],
    [Horizontal scale], [4 µs/div (acquisition window approximately 40 µs)],
    [Sampling rate, record length], [250 MS/s, 10 000 samples],
    [Trigger], [Auto mode, source CH1, level 0.00 V],
    [Measurement], [CH1 Max only],
  ),
  caption: [Oscilloscope settings used for all acquisitions.],
) <tab:scope-settings>

// TODO (lab partner): if Autoset was used, add here:
// "The timebase and trigger settings were set by the oscilloscope's Autoset function."

The intended procedure was to determine the minimum, mean, and maximum output voltages at each distance. During acquisition, however, only the maximum-voltage measurement (CH1 Max) was enabled. The oscilloscope therefore did not record the minimum and the mean. They were estimated afterwards from the saved screenshots.

=== Estimation of minimum and mean <sec:estimation>

In each screenshot, the vertical positions of the upper edge, the lower edge, and the centre of the trace were read from the graticule (100 mV/div, CH1 marker at 0 V; one pixel corresponds to 2 mV). The lower edge gives the minimum. The centre of the trace, averaged over the width of the acquisition, gives the mean; this assumes that the fluctuation is symmetric about the mean. The upper edge reproduces the CH1 Max *Value* readout within 6 mV at all ten distances. The estimates are therefore uncertain by about ±6 mV. They describe the 40 µs acquisition window only. The estimated values are listed in @tab:exercise2-oscilloscope.

== Expectation

The output was expected to remain approximately constant while the target distance remained unchanged. When the target moved closer to or farther from the sensor, a transition of finite duration was expected before the output reached its new level.

== Results

=== Oscilloscope traces

In all acquisitions the output appears as a nearly horizontal band with a fast fluctuation. Five representative acquisitions are shown in @fig:scope25 to @fig:scope200; the remaining acquisitions are in @app:scope. In the annotated screenshots, the maximum is the CH1 Max *Value* readout, and the mean and minimum are the estimates described above.

#scope-capture(25, [Floor level: the mean is about #mv(at-d(VoscMean, 25)) mV, and the fluctuation is about #span-at(25) mV wide.]) <fig:scope25>
#scope-capture(50, [The mean is about #mv(at-d(VoscMean, 50)) mV (expected: #mv(at-d(expected, 50)) mV); the fluctuation is about #span-at(50) mV wide.]) <fig:scope50>
#scope-capture(100, [The mean is about #mv(at-d(VoscMean, 100)) mV (expected: #mv(at-d(expected, 100)) mV); the fluctuation is about #span-at(100) mV wide.]) <fig:scope100>
#scope-capture(150, [The mean is about #mv(at-d(VoscMean, 150)) mV, far below the expected #mv(at-d(expected, 150)) mV.]) <fig:scope150>
#scope-capture(200, [The mean is about #mv(at-d(VoscMean, 200)) mV (expected: #mv(at-d(expected, 200)) mV), the same level as at 150 cm.]) <fig:scope200>

=== Characteristic curves

@tab:exercise2-oscilloscope lists the recorded maximum, the estimated minimum and mean, and the multimeter reading. @fig:osc-characteristic shows the same data together with the expected characteristic.

For each measurement point $i$, the absolute voltage deviation was calculated as

$ Delta U_i = |U_("expected", i) - U_("osc", i)|, $

where $U_("osc", i)$ is either the estimated mean or the recorded maximum at reference distance $d_i$. The absolute value gives the magnitude of the difference irrespective of its sign. The expected voltages use the same nominal 5 V supply and 25 cm floor as Experiment 1. Values in @tab:exercise2-oscilloscope are expressed in mV and were calculated before rounding; the minimum and mean are estimates (±6 mV).

#figure(
  table(
    columns: (8%, 12%, 12%, 12%, 12%, 12%, 16%, 16%), align: right,
    inset: 4pt, stroke: 0.4pt + rgb("D4DEE6"),
    table.header(
      [*$d$ (cm)*], [*$U_("exp")$ (mV)*], [*$U_("multi")$ (mV)*],
      [*$U_("min")$ (mV)*], [*$U_("mean")$ (mV)*], [*$U_("max")$ (mV)*],
      [*$Delta U_("mean")$ (mV)*], [*$Delta U_("max")$ (mV)*],
    ),
    ..range(n).map(i => (
      [#distances.at(i)],
      [#calc.round(expected.at(i) * 1000, digits: 2)],
      [#calc.round(Vmulti.at(i) * 1000, digits: 0)],
      [#calc.round(VoscMin.at(i) * 1000, digits: 0)],
      [#calc.round(VoscMean.at(i) * 1000, digits: 0)],
      [#calc.round(VoscMax.at(i) * 1000, digits: 0)],
      [#calc.round(mean-deviations.at(i) * 1000, digits: 2)],
      [#calc.round(osc-deviations.at(i) * 1000, digits: 2)],
    )).flatten(),
  ),
  caption: [Oscilloscope minimum and mean (estimated from the screenshots, ±6 mV), recorded maximum (CH1 Max Value), multimeter reading, expected voltage, and absolute deviations of the mean and the maximum from the expected voltage.],
) <tab:exercise2-oscilloscope>

#report-figure(image("../plots/osc_stats_plot.svg", width: 100%), "Oscilloscope maximum, estimated mean and minimum, multimeter readings, and the expected characteristic at the ten reference distances. The vertical lines connect minimum and maximum.") <fig:osc-characteristic>

The largest deviation of the recorded maxima from the expected voltage occurred at #distances.at(max-osc-index) cm: the expected voltage was #calc.round(expected.at(max-osc-index) * 1000, digits: 2) mV and the recorded maximum was #calc.round(VoscMax.at(max-osc-index) * 1000, digits: 2) mV, giving a deviation of #calc.round(max-osc * 1000, digits: 2) mV. For the estimated mean, the largest deviation was #calc.round(max-mean * 1000, digits: 2) mV at #distances.at(max-mean-index) cm. These values refer to the available acquisition windows and are not maxima established over complete ranging cycles.

== Assessment

*Q1 – How do the results fit Experiment 1?* From 10 cm to 100 cm the estimated oscilloscope mean agrees with the multimeter reading within #mv(max-mean-vs-multi) mV. The recorded maxima lie above the multimeter readings because the maximum is the upper edge of a fluctuation that is #span-min to #span-max mV wide; the mean is not affected by this. At 150 cm and 200 cm the two instruments disagree: the mean is #mv(at-d(VoscMean, 150)) mV and #mv(at-d(VoscMean, 200)) mV, whereas the multimeter reads #mv(at-d(Vmulti, 150)) mV and #mv(at-d(Vmulti, 200)) mV.

*Q2 – In which range does the sensor provide a suitable output signal?* In the same range as in Experiment 1, from 40 cm to 100 cm. At 150 cm, 160 cm, and 200 cm the traces are practically identical, so these acquisitions carry no distance information.

*Q3 – How well does the characteristic fit the datasheet curve?* From 40 cm to 100 cm the estimated mean follows the expected line within #mv(max-usable-mean) mV. At 25 cm and below the mean lies at #calc.round(calc.min(..floor-mean) * 1000, digits: 0) to #calc.round(calc.max(..floor-mean) * 1000, digits: 0) mV instead of the nominal 61.04 mV. Above 100 cm the mean stays at about #mv(at-d(VoscMean, 150)) mV and does not follow the expected line.

*Q4 – What is the maximum deviation from the specified curve?* For the estimated mean the largest deviation is #calc.round(max-mean * 1000, digits: 2) mV at #distances.at(max-mean-index) cm; for the recorded maxima it is #calc.round(max-osc * 1000, digits: 2) mV at #distances.at(max-osc-index) cm. Within 40 cm to 100 cm the deviation of the mean is at most #mv(max-usable-mean) mV.

*Q5 – Which additional information does the oscilloscope provide?* The output is not a constant voltage. A fast fluctuation that is #span-min to #span-max mV wide (about #calc.round(span-min * cm-per-mv, digits: 0) to #calc.round(span-max * cm-per-mv, digits: 0) cm on the nominal scale) is superimposed on the mean level. The multimeter hides this fluctuation by averaging. For a measurement with an ADC it means that single samples scatter by several ADC steps (@sec:adc).

=== Limitations of the measurement <sec:limitations>

- *Acquisition window.* At 4 µs/div the acquisition window is approximately 40 µs, compared with a sensor ranging cycle of approximately 99 ms @maxbotix. Each acquisition covers about $1 / 2500$ of a ranging cycle. The acquisitions show local voltage levels and fast fluctuation, but not the output behavior over a complete cycle.
- *Maximum only.* Only the CH1 Max measurement was enabled. Its *Value* gives the maximum of the current acquisition. The *Mean*, *Min*, and *Max* columns describe statistics of these maxima across acquisitions @tektronix; they are not waveform mean and minimum. The waveform minimum and mean were estimated from the screenshots (@sec:estimation).
- *Trigger.* The trigger was in Auto mode with a level of 0.00 V (visible in every screenshot). The sensor output stays above this level, so the oscilloscope was not triggered by the signal and ran freely. The acquisitions are therefore not synchronised with the ranging cycle of the sensor, and each shows an arbitrary 40 µs section. The measurement could not be repeated with different settings.
- *Statistics columns.* In every screenshot, including the first one at 10 cm, the Min and Max columns of the CH1 Max row read 88.0 mV and 512 mV. These statistics therefore include acquisitions from before the measurement series and were not reset between distances. They are not used in this report.
- *Target and repeatability.* The cardboard target was positioned manually (@fig:setup-views) and each distance was measured once. A tilt or misalignment of the target cannot be excluded, and repeatability was not tested.

*Behavior at 150 cm to 200 cm.* At 150 cm, 160 cm, and 200 cm the traces are practically identical. The mean of about #mv(at-d(VoscMean, 200)) mV corresponds to about #calc.round(at-d(VoscMean, 200) / volts-per-cm, digits: 0) cm on the nominal scale, although the target distances differ by up to 50 cm. The multimeter reads #mv(at-d(Vmulti, 150)) mV and #mv(at-d(Vmulti, 200)) mV at 150 cm and 200 cm, so the two instruments disagree there. The oscilloscope shows 40 µs of a cycle of about 99 ms, whereas the multimeter averages over a longer time, and the datasheet states that the analog output follows the most recent range reading @maxbotix. A possible explanation is that the output was not constant in time at these distances, for example because it alternated between different range values. This was not verified. Other possible causes are the alignment of the manually positioned target and reflections from the floor and from nearby equipment. The available data do not show which of these applies.

=== Sampling the output with an ADC at 10 kHz <sec:adc>

The lab sheet asks whether a sampling rate of approximately 10 kHz is sufficient to read the sensor output and which problems are expected.

*Signal content.* The analog output follows the most recent range reading, which the sensor updates about every 99 ms (about 10 Hz) @maxbotix. At 10 kHz, successive samples are 100 µs apart, which gives about 1000 samples per update. This is far more than needed to follow the changes of the signal itself.

*Noise.* The screenshots show a fast fluctuation of #span-min to #span-max mV on top of the mean level, which changes within the 40 µs window. Components above the Nyquist limit of 5 kHz fold into the sampled signal (aliasing) unless they are attenuated before the conversion, and they appear as random scatter between consecutive samples. For a 10-bit ADC with a 5 V reference (about #calc.round(adc-step, digits: 1) mV per step) the fluctuation spans about #calc.round(span-min / adc-step, digits: 0) to #calc.round(span-max / adc-step, digits: 0) steps.

*Consequences and countermeasures.* A single ADC sample is not a reliable distance reading. A low-pass filter in front of the ADC input, with a cut-off clearly below 5 kHz, limits aliasing, and averaging many samples per reading reduces the scatter. The averaging window should lie inside one update period of about 99 ms, because the output can change when the sensor updates.

The acquisitions in this report cover only 40 µs and were not recorded with an ADC, so they show the size of the fluctuation but do not quantify the effects of the sampling itself.

= Conclusion

The analog output characteristic was assessed at ten reference distances using a multimeter and the oscilloscope. The multimeter readings followed the expected characteristic most closely between 40 cm and 100 cm, where the distance error was at most #calc.round(max-usable / volts-per-cm, digits: 2) cm. The slope in this range is #calc.round(slope-change, digits: 1) % below the nominal value. The largest absolute voltage deviation of the multimeter was #calc.round(max-multi * 1000, digits: 2) mV at #distances.at(max-multi-index) cm, equivalent to #calc.round(max-multi / volts-per-cm, digits: 2) cm. The estimated oscilloscope mean agrees with the multimeter within #mv(max-mean-vs-multi) mV up to 100 cm. Beyond 100 cm the oscilloscope and the multimeter disagree, and the cause could not be determined from the available data.

The oscilloscope measurements have limits: only the maximum was measured directly, the minimum and mean were estimated from the screenshots, each acquisition covers 40 µs of a 99 ms cycle, and the trigger was in Auto mode. The results therefore support a comparison of the recorded characteristics up to 100 cm, but not a complete assessment of the output over a ranging cycle. The oscilloscope shows a fast fluctuation of #span-min to #span-max mV on the output. An ADC measurement of this signal should use an analog low-pass filter and averaging.

#pagebreak(weak: true)
#bibliography("references.bib", style: "ieee", title: [References])

#pagebreak()
= Appendix

== Additional oscilloscope captures <app:scope>

The acquisitions at 25, 50, 100, 150, and 200 cm appear in the main text. All other available sensor-output captures are reproduced here, including the supplementary captures at 27 cm and 160 cm. Each acquisition uses 4 µs/div, 250 MS/s, and 10,000 samples; CH1 uses 100 mV/div.

#let main-distances = (25, 50, 100, 150, 200)
#let supplementary = captures.filter(capture => not main-distances.contains(capture.distance))
#for (index, capture) in supplementary.enumerate() {
  if index > 0 and calc.rem(index, 2) == 0 { pagebreak() }
  scope-capture-plain(capture.distance, width: if index < 2 { 86% } else { 90% })
}
