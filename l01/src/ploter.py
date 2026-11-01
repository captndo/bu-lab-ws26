"""Analyse multimeter voltages and recorded oscilloscope maxima.

Input: CSV columns d (cm), v_multi (mV), v_osc_max (mV).

"""

import argparse
import csv
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt

SUPPLY_VOLTAGE = 5.0
VOLTS_PER_CM = SUPPLY_VOLTAGE / 2048
MIN_DISTANCE_CM = 25


def expected_voltage(distance):
    return max(distance, MIN_DISTANCE_CM) * VOLTS_PER_CM


def load_measurements(csv_path):
    with Path(csv_path).open(
        newline="", encoding="utf-8-sig"
    ) as source:
        rows = list(csv.DictReader(source))
    distances = [int(row["d"]) for row in rows]
    if not distances or any(distance <= 0 for distance in distances):
        raise ValueError("Reference distances must be positive.")
    if distances != sorted(set(distances)):
        raise ValueError("Reference distances must be unique and increasing.")
    return (
        distances,
        [expected_voltage(distance) for distance in distances],
        [float(row["v_multi"]) / 1000 for row in rows],
        [float(row["v_osc_max"]) / 1000 for row in rows],
    )


def calculate_deviations(distances, expectations, multimeter, osc_max):
    """Use volts for calculations; distance error is defined from 25 cm."""
    results = []
    for d, expected, multi, maximum in zip(
        distances, expectations, multimeter, osc_max
    ):
        error = multi - expected
        indicated = multi / VOLTS_PER_CM if d >= MIN_DISTANCE_CM else None
        results.append({
            "d": d,
            "expected": expected,
            "multi": multi,
            "osc_max": maximum,
            "multi_error": error,
            "multi_deviation": abs(error),
            "osc_deviation": abs(maximum - expected),
            "indicated_distance": indicated,
            "distance_error": None if indicated is None else indicated - d,
        })
    return results


def print_results(results):
    print("Measured voltages and errors; error columns are absolute deviations.")
    print("d(cm)  Expected(mV)  Multimeter(mV)  ScopeMax(mV)  "
          "MultiErr(mV)  ScopeErr(mV)  Indicated(cm)  DistErr(cm)")
    for row in results:
        distance_error = row["distance_error"]
        distance_text = (
            "--" if distance_error is None
            else f"{abs(distance_error):.2f}"
        )
        indicated = row["indicated_distance"]
        indicated_text = "--" if indicated is None else f"{indicated:.2f}"
        print(
            f"{row['d']:5d}  {row['expected'] * 1000:12.2f}"
            f"  {row['multi'] * 1000:14.2f}"
            f"  {row['osc_max'] * 1000:12.2f}"
            f"  {row['multi_deviation'] * 1000:12.2f}"
            f"  {row['osc_deviation'] * 1000:12.2f}"
            f"  {indicated_text:>13}"
            f"  {distance_text:>11}"
        )
    for key, label in (
        ("multi_deviation", "Multimeter"),
        ("osc_deviation", "Oscilloscope maximum"),
    ):
        row = max(results, key=lambda result: result[key])
        print(
            f"{label}: largest absolute voltage deviation = "
            f"{row[key] * 1000:.2f} mV at {row['d']} cm"
        )
    valid = [row for row in results if row["distance_error"] is not None]
    row = max(valid, key=lambda result: abs(result["distance_error"]))
    print(
        "Multimeter: largest absolute distance error = "
        f"{abs(row['distance_error']):.2f} cm at {row['d']} cm"
    )


def style_axes(ax):
    ax.set_facecolor("white")
    ax.set_axisbelow(True)
    ax.grid(True, color="#D9DDE2", linewidth=0.65)
    ax.spines[["top", "right"]].set_visible(False)
    ax.tick_params(labelsize=10)


def save_plot(distances, expectations, series, output_path):
    fig, ax = plt.subplots(figsize=(7.2, 4.7), layout="constrained", facecolor="white")
    ax.set_title("Voltage vs. distance", fontsize=14, fontweight="bold", pad=12)
    style_axes(ax)
    ax.plot(distances, expectations, color="#333333", linestyle="--",
            linewidth=1.6, marker=".", markersize=5, label="Expected", zorder=2)
    for label, values, style in series:
        ax.scatter(distances, values, s=45, label=label, zorder=3, **style)
    ax.set_xlim(min(distances) - 5, max(distances) + 8)
    ax.set_ylim(0, 0.56)
    ax.set_xlabel("Distance (cm)", fontsize=11)
    ax.set_ylabel("Voltage (V)", fontsize=11)
    ax.set_xticks(distances)
    ax.tick_params(axis="x", labelrotation=45)
    handles, labels = ax.get_legend_handles_labels()
    fig.legend(handles, labels, loc="outside lower center", ncols=len(labels),
               frameon=False, fontsize=10)
    fig.savefig(output_path, facecolor="white")
    plt.close(fig)


def save_error_plot(results, output_path):
    points = [(row["d"], row["multi_error"]) for row in results
              if row["distance_error"] is not None]
    error_distances, voltage_errors = zip(*points)
    max_index = max(range(len(points)), key=lambda index: abs(voltage_errors[index]))
    max_distance = error_distances[max_index]
    fig, axes = plt.subplots(2, 1, sharex=True, figsize=(7.2, 7.4),
                             layout="constrained", facecolor="white")
    fig.suptitle("Multimeter errors (25–200 cm)", fontsize=14, fontweight="bold")
    panels = [
        (1000, "mV", "Voltage error", "Measured − expected voltage (mV)"),
        (1 / VOLTS_PER_CM, "cm", "Distance error",
         "Indicated − reference distance (cm)"),
    ]
    for ax, (scale, unit, title, ylabel) in zip(axes, panels):
        errors = [error * scale for error in voltage_errors]
        max_error = errors[max_index]
        style_axes(ax)
        ax.set_title(title, fontsize=12, pad=10)
        ax.axhline(0, color="#333333", linestyle="--", linewidth=1.5, zorder=2)
        ax.scatter(error_distances, errors, s=45, marker="o", facecolors="none",
                   edgecolors="#0072B2", linewidths=1.5, zorder=3)
        ax.scatter([max_distance], [max_error], s=65, marker="D", color="#D55E00",
                   edgecolors="white", linewidths=0.6, zorder=4,
                   label=(f"Max. |error|: {abs(max_error):.2f} {unit} "
                          f"at {max_distance} cm"))
        limit = max(1, max(abs(error) for error in errors) * 1.2)
        ax.set_ylim(-limit, limit)
        ax.set_xlim(min(error_distances) - 5, max(error_distances) + 8)
        ax.set_ylabel(ylabel, fontsize=11)
        ax.legend(loc="upper right", frameon=False, fontsize=10)
    axes[-1].set_xlabel("Distance (cm)", fontsize=11)
    axes[-1].set_xticks(error_distances)
    axes[-1].tick_params(axis="x", labelrotation=45)
    fig.savefig(output_path, facecolor="white")
    plt.close(fig)


def main(input_path="measurements.csv", output_dir="plots"):
    distances, expectations, multimeter, osc_max = load_measurements(input_path)
    results = calculate_deviations(
        distances, expectations, multimeter, osc_max
    )
    print_results(results)
    plot_dir = Path(output_dir)
    plot_dir.mkdir(parents=True, exist_ok=True)
    series = [
        ("Multimeter", multimeter, dict(marker="o", facecolors="none",
                                       edgecolors="#0072B2", linewidths=1.5)),
        ("Oscilloscope max", osc_max, dict(marker="^", color="#996000",
                                         edgecolors="white", linewidths=0.6)),
    ]
    for filename, included in (
        ("expectation_plot.svg", []),
        ("multimeter_plot.svg", series[:1]),
        ("osc_plot.svg", series),
    ):
        save_plot(distances, expectations, included, plot_dir / filename)
    save_error_plot(results, plot_dir / "multimeter_error_plot.svg")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, default=Path("measurements.csv"))
    parser.add_argument("--output", type=Path, default=Path("plots"))
    args = parser.parse_args()
    main(args.input, args.output)
