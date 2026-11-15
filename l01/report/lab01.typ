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
#let comparison-indices = range(distances.len()).filter(i => distances.at(i) >= 40 and distances.at(i) <= 100)
#let max-comparison = calc.max(..comparison-indices.map(i => multi-deviations.at(i)))
#let max-comparison-index = comparison-indices.find(i => multi-deviations.at(i) == max-comparison)
#let comparison-fit = {
  let xs = comparison-indices.map(i => float(distances.at(i)))
  let ys = comparison-indices.map(i => Vmulti.at(i))
  let n = xs.len()
  let sx = xs.sum()
  let sy = ys.sum()
  let sxy = range(n).map(i => xs.at(i) * ys.at(i)).sum()
  let sxx = xs.map(x => x * x).sum()
  let slope = (n * sxy - sx * sy) / (n * sxx - sx * sx)
  (slope: slope, offset: (sy - slope * sx) / n)
}
#let max-osc = calc.max(..osc-deviations)
#let max-osc-index = osc-deviations.position(value => value == max-osc)
#let captures = json("../plots/osc_captures.json")
#let scope-capture(distance, observation: none, width: 90%) = report-figure(
  image("../data/osc/" + str(distance) + "cm.png", width: width),
  [Sensor output acquisition at a reference distance of #distance cm.#if observation != none { [ #observation] }],
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

The sensor and Arduino breadboard were mounted on a tripod positioned at the edge of a table. A ruler was placed beneath the tripod, with its scale extending in the measurement direction. The cardboard box served as the reflecting target and was positioned manually. The reference distance $d$ was measured from the front of the sensor to the cardboard target using the ruler. @fig:setup-views shows the ruler, the measurement direction, and the target.

The analog output and ground terminals of the sensor were connected to the positive and negative multimeter probes, respectively. The Arduino supplied the sensor's 5 V supply and shared ground reference. @fig:connections shows the electrical connections.

#report-figure(image("../data/images/setup.jpeg", height: 20%), "Annotated sensor, supply, ground, and multimeter connections.", ) <fig:connections>

#figure(
  grid(
    columns: (1fr, 1fr), gutter: 7mm,
    image("../data/images/setup_profile.png", width: 100%, height: 82mm, fit: "contain"),
    image("../data/images/setup_behind.png", width: 100%, height: 82mm, fit: "contain"),
  ),
  caption: [Side and rear views of the tripod-mounted sensor, ruler, and cardboard target. The reference distance is measured from the sensor front to the target using the ruler.],
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

The signed voltage error at measurement point $i$ was calculated as

$ e_(U, i) = U_("multi", i) - U_("expected", i). $

Here, $U_("multi", i)$ is the recorded multimeter voltage and $U_("expected", i)$ is the expected voltage at reference distance $d_i$. Positive errors indicate readings above the expectation; negative errors indicate readings below it. The absolute voltage deviation is $Delta U_i = |e_(U, i)|$.

For reference distances of at least 25 cm, the indicated distance and its signed error were calculated using

$ d_("ind", i) = (2048 / 5) U_("multi", i), quad
  e_(d, i) = d_("ind", i) - d_i = (2048 / 5) e_(U, i). $

Voltages in these expressions are in V and distances are in cm. Distance conversion and distance error are not evaluated for the 10 cm and 20 cm reference points because these lie below the specified minimum reported distance. Their voltage deviations are still evaluated against the nominal 25 cm floor.

@fig:multi-errors shows the signed voltage and distance errors for 25–200 cm. @tab:exercise1-multimeter reports absolute deviations; its voltages and deviations were calculated before rounding the displayed values. A dash denotes distance entries that are not evaluated below the specified minimum reported distance.


#report-figure(image("../plots/multimeter_error_plot.svg", width: 90%), "Signed multimeter voltage and distance errors for reference distances of 25–200 cm. The dashed line marks zero error; the diamond marks the largest absolute error.") <fig:multi-errors>

== Assessment

*Q1 – Why were these distances selected?* The distances are not equally spaced. They were chosen to resolve the features of the characteristic. The distances 10, 20, and 25 cm lie at and below the minimum reported distance and show the flat floor. The distances 30, 40, and 50 cm cover the near-field region, where the datasheet reports reduced accuracy. The distances 75, 100, 150, and 200 cm cover the linear region up to the 2 m that the ruler allowed. More points were placed where the characteristic changes (25 to 50 cm) than where it is linear.

*Q2 – In which distance range is the output usable?* The most suitable range is between 40 cm and 100 cm, where the maximum absolute recorded distance error was 2.43 cm (5.93 mV at 50 cm). At and below 25 cm the output stays between 73 mV and 76 mV (10 cm and 20 cm)  and carries no distance information. At 150 cm and 200 cm, the readings fall bellow the reference distances by approximately 14.83 cm and 17.32 cm. Each distance was measured once, so repeatability and reliable operation throughout the 40–100 cm interval were not established.

*Q3 – How well does the characteristic fit the datasheet curve?* The measured characteristic approximately agrees with the expected shape: a nearly flat close-range output followed by an increasing voltage. At 10, 20, and 25 cm, the measured level was 73–76 mV rather than the nominal 61.04 mV. A linear fit to the four multimeter readings from 40 cm to 100 cm gives a slope of #calc.round(comparison-fit.slope * 1000, digits: 2) mV/cm instead of the nominal #calc.round(volts-per-cm * 1000, digits: 3) mV/cm (#calc.round((1 - comparison-fit.slope / volts-per-cm) * 100, digits: 1) % lower). This fit describes only those four sampled points and does not establish an intrinsic sensor gain error. At the sampled distances of 150 cm and 200 cm, the readings fell further below the nominal characteristic.

*Q4 – What is the maximum deviation?* The largest absolute voltage deviation among the ten readings occurred at #distances.at(max-multi-index) cm: the measured voltage was #calc.round(Vmulti.at(max-multi-index) * 1000, digits: 2) mV instead of #calc.round(expected.at(max-multi-index) * 1000, digits: 2) mV. The output was therefore #calc.round(max-multi * 1000, digits: 2) mV below expectation, corresponding to a distance underestimate of #calc.round(max-multi / volts-per-cm, digits: 2) cm (#calc.round(max-multi / volts-per-cm / distances.at(max-multi-index) * 100, digits: 1) % of the reference distance). Within the 40–100 cm subset, the largest absolute voltage deviation was #calc.round(max-comparison * 1000, digits: 2) mV at #distances.at(max-comparison-index) cm, corresponding to an absolute distance error of #calc.round(max-comparison / volts-per-cm, digits: 2) cm.

*Further influences.* The nominal relationship also depends on supply voltage and ambient temperature. The output voltage is proportional to the supply voltage, but the supply was not measured simultaneously with the output. The analysis therefore assumes the nominal Arduino supply of 5 V rather than a measured supply value. In addition, the speed of sound changes by approximately 0.6 m/s per degree Celsius. The manufacturer provides a temperature-compensation expression, but no ambient-temperature measurements were recorded and this correction could not be applied @maxbotix @temperature.

= Experiment 2 — Oscilloscope Characteristic

== Objective

The objective was to investigate the temporal behavior of the sensor output and to compare its minimum, mean, and maximum voltages with Experiment 1 and the sensor datasheet.

*Deviation from the prescribed procedure.* We did not follow the oscilloscope measurement procedure correctly. Only the CH1 Max measurement was enabled for the sensor output. We mistakenly interpreted its statistical *Mean* and *Min* columns as separate waveform measurements. Consequently, waveform mean and minimum values were not recorded, and the required min/mean/max characterization remained incomplete. The following characteristic comparison uses only the recorded CH1 Max *Value* entries.

== Setup

The setup from Experiment 1 was retained, with the multimeter replaced by an oscilloscope probe. The probe tip on channel CH1 was connected to the sensor's analog output $U_("out")$, and the probe ground clip was connected to the shared sensor/Arduino GND. The Arduino continued to provide the 5 V supply. @fig:osc-setup shows the annotated setup.

#report-figure(image("../data/images/setup_osc.png", height: 30%), "Laboratory arrangement for observing the sensor output: CH1 probe tip on the analog output, with the probe ground clip on the shared sensor/Arduino GND.") <fig:osc-setup>

== Procedure

The probe was set to 1× attenuation and its response was checked using the oscilloscope's built-in reference signal, shown in @fig:probe-check. This documents the reference-signal check rather than an independent calibration of the voltage scale.
#report-figure(image("../data/images/probe_calib.jpeg", width: 90%), "Oscilloscope display during the probe response check using the built-in reference signal.") <fig:probe-check>

Measurements were performed at the same ten reference distances as in Experiment 1. Autoset was used to configure the oscilloscope. @tab:scope-settings lists the settings visible in the saved sensor-output acquisitions. A second measurement row for CH2 is displayed, but CH2 is not used in this evaluation.

#figure(
  table(
    columns: (35%, 65%), align: left,
    inset: 5pt, stroke: 0.4pt + rgb("D4DEE6"),
    table.header([*Setting*], [*Value*]),
    [Vertical scale (CH1)], [100 mV/div],
    [Horizontal scale], [4 µs/div],
    [Sampling rate and record length], [250 MS/s; 10,000 samples],
    [Trigger], [Auto mode; source CH1; level 0.00 V],
    [Sensor-output measurement], [CH1 Max only],
  ),
  caption: [Settings visible in the saved sensor-output acquisitions after Autoset.],
) <tab:scope-settings>


At 250 MS/s, a record of 10,000 samples spans approximately 40 µs. The visible traces remain above the 0 V trigger level. Auto mode allows acquisitions without a signal-trigger event, so these records do not establish synchronization with the sensor's ranging cycle @tektronix. The resulting limitations are discussed in @sec:limitations.


== Expectation

At a fixed target distance, the analog output was expected to settle near the nominal voltage calculated in Experiment 1. The sensor updates its range data approximately every 99 ms, and the analog output corresponds to the most recent range data @maxbotix. Observing a complete ranging cycle would be necessary to assess settling behavior and disturbances occurring at other times within that cycle.

== Results

=== Characteristic comparison

@tab:exercise2-oscilloscope lists the recorded maxima together with the multimeter readings, expected voltages, and absolute deviations. Waveform mean and minimum measurements are unavailable. @fig:osc-characteristic compares the recorded characteristic with Experiment 1 and the nominal relationship.

For each measurement point $i$, the absolute voltage deviation was calculated as

$ Delta U_i = |U_("osc,max", i) - U_("expected", i)|. $

Here, $U_("osc,max", i)$ is the CH1 Max *Value* recorded at reference distance $d_i$. Expected voltages use the same nominal 5 V supply and 25 cm floor as Experiment 1. Values in the table are in mV and were calculated before rounding.

#figure(
  table(
    columns: (12%, 22%, 22%, 23%, 21%), align: right,
    inset: 4pt, stroke: 0.4pt + rgb("D4DEE6"),
    table.header([*$d$ (cm)*], [*$U_("expected")$ (mV)*], [*$U_("multi")$ (mV)*], [*$U_("osc,max")$ (mV)*], [*$Delta U$ (mV)*]),
    ..range(distances.len()).map(i => (
      [#distances.at(i)],
      [#calc.round(expected.at(i) * 1000, digits: 2)],
      [#calc.round(Vmulti.at(i) * 1000, digits: 2)],
      [#calc.round(VoscMax.at(i) * 1000, digits: 2)],
      [#calc.round(osc-deviations.at(i) * 1000, digits: 2)],
    )).flatten(),
  ),
  caption: [Recorded oscilloscope maxima, multimeter readings, nominal expected voltages, and absolute deviations of the maxima from expectation.],
) <tab:exercise2-oscilloscope>

#report-figure(image("../plots/osc_plot.svg", width: 100%), "Recorded oscilloscope maxima, multimeter readings, and the expected characteristic at the ten reference distances.") <fig:osc-characteristic>

=== Oscilloscope traces

Five representative acquisitions are shown in @fig:scope25, @fig:scope50, @fig:scope100, @fig:scope150, and @fig:scope200. The remaining seven captures appear in @app:scope. Each trace shows a nearly horizontal voltage band with fast fluctuations within the short acquisition window.

The sensor measurement is identified by the blue *1 Max* label in the bottom measurement table. Its *Value* column gives the recorded maximum. For example, at 50 cm (@fig:scope50), *Value* is 132 mV, whereas the statistical *Mean*, *Min*, and *Max* entries are 232 mV, 88 mV, and 512 mV. These latter entries summarize maximum-voltage measurements across acquisitions; they do not give the current waveform's mean and minimum @tektronix. The statistical Min and Max entries remain unchanged across the saved distances and cannot be used as separate measurements for each distance.

#scope-capture(25, observation: [The recorded maximum is 92 mV, above the nominal close-range level of 61.04 mV.]) <fig:scope25>
#scope-capture(50, observation: [The recorded maximum is 132 mV, compared with an expected 122.07 mV. The bottom CH1 Max row distinguishes the current Value from its statistical columns.]) <fig:scope50>
#scope-capture(100, observation: [The recorded maximum is 252 mV, compared with an expected 244.14 mV; the trace level has increased relative to 50 cm.]) <fig:scope100>
#scope-capture(150, observation: [The recorded maximum is 280 mV, below the expected 366.21 mV.]) <fig:scope150>
#scope-capture(200, observation: [The recorded maximum remains at 280 mV despite the greater target distance; the expected voltage is 488.28 mV.]) <fig:scope200>

== Assessment

*Q1 – How do the results fit Experiment 1?* Between 25 cm and 100 cm, both instruments show an increasing voltage with distance. The recorded oscilloscope maxima are higher than the corresponding multimeter readings. This may partly reflect the different measurement quantities: a maximum over a short acquisition window and a multimeter DC reading. At 150 cm and 200 cm, the recorded maximum remains at 280 mV, whereas the multimeter readings increase from 330 mV to 446 mV. This disagreement cannot be resolved from the available acquisitions.

*Q2 – In which range does the sensor provide a suitable output signal?* The sampled oscilloscope maxima show the closest agreement with the nominal characteristic at 50 cm and 100 cm, with deviations of 9.93 mV and 7.86 mV; the deviation at the intermediate 75 cm point is 20.89 mV. These points support a distance-dependent response over 50–100 cm in this setup. The similar close-range levels and identical maxima at 150 cm and 200 cm limit discrimination at those sampled distances. The short records and absence of repeated measurements do not establish a continuously reliable operating interval.

*Q3 – How well does the characteristic fit the datasheet curve?* The recorded maxima show a nearly flat close-range response at 10, 20, and 25 cm (100, 96, and 92 mV), above the nominal 61.04 mV floor. Above 25 cm, the maxima increase toward the nominal characteristic through 100 cm. At 150 cm and 200 cm, they fall below expectation by 86.21 mV and 208.28 mV. This is a comparison of acquisition maxima with a nominal output characteristic; the missing waveform mean prevents a complete comparison of the intended measurement quantities.

*Q4 – What is the maximum deviation from the specified curve?* The largest absolute deviation among the recorded maxima occurred at #distances.at(max-osc-index) cm. The expected voltage was #calc.round(expected.at(max-osc-index) * 1000, digits: 2) mV and the recorded maximum was #calc.round(VoscMax.at(max-osc-index) * 1000, digits: 2) mV, giving a deviation of #calc.round(max-osc * 1000, digits: 2) mV below expectation. This result applies to the saved acquisition windows; it is not a maximum established over complete ranging cycles.

#block(breakable: false)[
*Q5 – Which additional information does the oscilloscope provide?* The acquisitions reveal fast voltage fluctuations around a local output level that a single multimeter reading does not show. An ADC sample can therefore depend on the instant of acquisition. The short records do not establish the fluctuation statistics, frequency spectrum, or behavior over a ranging cycle. Possible sampling problems and countermeasures are discussed in @sec:adc.
]

=== Limitations of the measurement <sec:limitations>

Only maximum-voltage measurements were obtained; the statistical columns cannot recover the missing waveform mean and minimum. The approximately 40 µs acquisition window covers about $1 / 2500$ of the approximately 99 ms ranging cycle @maxbotix. Together with the Auto trigger settings, this prevents conclusions about cycle-wide disturbances or settling. The target was positioned manually and each reference distance was measured once, so target alignment and repeatability were not independently assessed.

At 150 cm, 160 cm, and 200 cm, the saved traces show similar local levels, despite the different target distances. Possible explanations include reflections from the floor or nearby equipment, target alignment, or changes between different reported ranges over time. The multimeter and oscilloscope also observe different time windows and were used in separate measurements. The available records do not distinguish among these explanations or establish an intrinsic upper range limit of the sensor.

=== Sampling the output with an ADC at 10 kHz <sec:adc>

At 10 kHz, successive ADC samples are 100 µs apart, giving approximately 990 samples per 99 ms sensor update period. This is frequent relative to range updates, but the update rate alone does not establish that the output is sampled correctly during settling or disturbances. Each saved oscilloscope record spans only 40 µs, less than one ADC sampling interval.

Frequency components above the 5 kHz Nyquist limit can alias into the sampled signal unless sufficiently attenuated before conversion. The visible fluctuations indicate that individual samples may vary, but these captures do not quantify their spectrum or the resulting ADC error. An analog low-pass filter with sufficient attenuation above 5 kHz could limit aliasing.

The results therefore identify potential sampling problems and countermeasures, but do not establish whether 10 kHz is sufficient for this setup. A longer observation spanning complete ranging cycles would be needed to assess the timing of output updates and choose suitable sampling or averaging windows.

= Conclusion

The analog output characteristic was assessed at ten reference distances using a multimeter and recorded oscilloscope maxima. The multimeter readings followed the nominal characteristic most closely among the sampled points from 40 cm to 100 cm, where the largest absolute distance error was #calc.round(max-comparison / volts-per-cm, digits: 2) cm. Its largest absolute voltage deviation overall was #calc.round(max-multi * 1000, digits: 2) mV at #distances.at(max-multi-index) cm, equivalent to a distance underestimate of #calc.round(max-multi / volts-per-cm, digits: 2) cm. For the recorded oscilloscope maxima, the largest absolute deviation was #calc.round(max-osc * 1000, digits: 2) mV at #distances.at(max-osc-index) cm. The disagreement between the instruments at 150 cm and 200 cm remains unexplained.

The intended oscilloscope characterization remained incomplete because separate waveform mean and minimum measurements were not recorded. Autoset produced short, unsynchronized acquisitions that do not characterize complete ranging cycles. These results support a qualified comparison of the recorded characteristics and identify potential ADC sampling problems, but do not establish cycle-wide fluctuations, repeatability, or sampling adequacy. Supplementary visual observations are provided in @app:visual-estimates; they do not replace the missing measurements.

#pagebreak(weak: true)
#bibliography("references.bib", style: "ieee", title: [References])

#pagebreak()
= Appendix

== Additional oscilloscope captures <app:scope>

The acquisitions at 25, 50, 100, 150, and 200 cm appear in the main text. The other seven available sensor-output captures are reproduced here, including the supplementary captures at 27 cm and 160 cm. Each acquisition uses 4 µs/div, 250 MS/s, and 10,000 samples; CH1 uses 100 mV/div.

#let main-distances = (25, 50, 100, 150, 200)
#let supplementary = captures.filter(capture => not main-distances.contains(capture.distance))
#for (index, capture) in supplementary.enumerate() {
  if index > 0 and calc.rem(index, 2) == 0 { pagebreak() }
  scope-capture(capture.distance, width: if index < 2 { 76% } else { 90% })
}

#pagebreak()
== Supplementary visual observations <app:visual-estimates>

For an illustrative comparison of the displayed trace levels, the centre and lower visible edge of the trace band were read from the saved screenshots using the 100 mV/div graticule and the CH1 zero marker. The values in @tab:visual-estimates are the previously prepared screenshot estimates, rounded to the nearest 10 mV to avoid implying fine measurement precision. They describe only the displayed acquisition windows and are not used in the main characteristic curves, deviations, or assessment.

The centre of a visible band would approximate a waveform mean only if the fluctuations were symmetric about it and the display represented their distribution adequately. Neither condition was established. Similarly, the lower visible edge is an approximate displayed envelope, not a recovery of the oscilloscope's automatic minimum measurement. Rasterization and trace thickness limit interpretation, and no numerical uncertainty interval is established for these estimates. They cannot replace the missing mean and minimum measurements required by the lab instructions.

#{
  set par(justify: false)
  let estimate-csv = csv("../data/osc_estimates.csv")
  let estimate-headers = estimate-csv.first()
  let distance-index = estimate-headers.position(name => name == "d")
  // These source columns contain visual centre/lower-edge readings, not
  // independently measured waveform means or minima.
  let centre-index = estimate-headers.position(name => name == "v_osc_mean")
  let lower-index = estimate-headers.position(name => name == "v_osc_min")
  let rows = estimate-csv.slice(1)
  assert(rows.map(row => int(row.at(distance-index))) == distances,
    message: "Visual estimates must use the same ten reference distances.")
  [#figure(
    table(
      columns: (20%, 40%, 40%), align: right,
      inset: 5pt, stroke: 0.4pt + rgb("D4DEE6"),
      table.header([*Reference distance (cm)*], [*Approximate trace centre (mV)*], [*Approximate lower visible edge (mV)*]),
      ..rows.map(row => (
        [#row.at(distance-index)],
        [#(10 * calc.round(float(row.at(centre-index)) / 10))],
        [#(10 * calc.round(float(row.at(lower-index)) / 10))],
      )).flatten(),
    ),
    caption: [Illustrative screenshot readings rounded to the nearest 10 mV. These are visual trace-level estimates, not measured waveform means or minima.],
  ) <tab:visual-estimates>]
}

@fig:estimate25, @fig:estimate50, @fig:estimate100, @fig:estimate150, and @fig:estimate200 show the annotated screenshots used to illustrate the estimates. The red annotation identifies the recorded maximum, while the green and orange annotations mark the visual trace-centre and lower-edge estimates. The existing image labels call these estimates "mean" and "min"; they are interpreted here with the limitations described above. The annotations retain the original estimated values, whereas @tab:visual-estimates rounds them to the nearest 10 mV.

#let estimate-capture(distance) = report-figure(
  image("../data/osc/annotated/" + str(distance) + "cm.png", width: 90%),
  [Annotated acquisition at #distance cm showing the recorded maximum and the visual trace-centre and lower-edge estimates.],
)

#pagebreak(weak: true)
#estimate-capture(25) <fig:estimate25>
#estimate-capture(50) <fig:estimate50>
#pagebreak(weak: true)
#estimate-capture(100) <fig:estimate100>
#estimate-capture(150) <fig:estimate150>
#pagebreak(weak: true)
#estimate-capture(200) <fig:estimate200>
