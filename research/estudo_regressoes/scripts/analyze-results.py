#!/usr/bin/env python3
"""Derive descriptive COTB P1/P3 tables and figures from preserved CSV files.

The script intentionally uses only Python's standard library plus the local
TeX/Poppler executables. It analyzes N1--N8 only; historical F1--F8 data are
not read or combined with the new experiment.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import math
import os
import shutil
import statistics
import subprocess
import tempfile
from collections import Counter, defaultdict
from pathlib import Path


SCRIPT = Path(__file__).resolve()
STUDY = SCRIPT.parents[1]
WORKSPACE = SCRIPT.parents[3]


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open("r", encoding="utf-8-sig", newline="") as stream:
        return list(csv.DictReader(stream))


def write_csv(path: Path, rows: list[dict[str, object]], fields: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=fields, lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def tex_escape(value: object) -> str:
    text = str(value)
    for old, new in (
        ("\\", r"\textbackslash{}"),
        ("&", r"\&"),
        ("%", r"\%"),
        ("$", r"\$"),
        ("#", r"\#"),
        ("_", r"\_"),
        ("{", r"\{"),
        ("}", r"\}"),
    ):
        text = text.replace(old, new)
    return text


def fmt_ms(value: float) -> str:
    if float(value).is_integer():
        return f"{int(value):,}".replace(",", ".")
    whole, decimal = f"{value:.1f}".split(".")
    return f"{int(whole):,}".replace(",", ".") + "," + decimal


def applicable(catalog_row: dict[str, str], strategy: str) -> bool:
    return not catalog_row[f"applicability_{strategy.lower()}"].startswith(
        "not_applicable"
    )


def classify_group(rows: list[dict[str, str]]) -> str:
    classes = [row["classification"] for row in rows]
    if "invalid_variant" in classes:
        return "invalid_variant"
    if "equivalent_variant" in classes:
        return "equivalent_variant"
    if len(rows) == 3 and all(item == "detected_assertion" for item in classes):
        return "detected_stable"
    if len(rows) == 3 and all(item == "survived" for item in classes):
        return "survived_stable"
    if any("infrastructure" in item for item in classes):
        return "inconclusive_infrastructure"
    return "unstable_inconclusive"


def run_command(command: list[str], cwd: Path, env: dict[str, str]) -> None:
    result = subprocess.run(
        command,
        cwd=cwd,
        env=env,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        check=False,
    )
    if result.returncode != 0:
        raise RuntimeError(
            f"Command failed ({result.returncode}): {' '.join(command)}\n{result.stdout}"
        )


def render_tex(tex_source: str, pdf_path: Path, png_path: Path) -> None:
    pdflatex = shutil.which("pdflatex")
    pdftocairo = shutil.which("pdftocairo")
    if not pdflatex or not pdftocairo:
        raise RuntimeError("pdflatex and pdftocairo are required to render figures")

    pdf_path.parent.mkdir(parents=True, exist_ok=True)
    png_path.parent.mkdir(parents=True, exist_ok=True)
    env = os.environ.copy()
    env["SOURCE_DATE_EPOCH"] = "0"
    env["FORCE_SOURCE_DATE"] = "1"

    render_root = STUDY / "derived" / ".render"
    render_root.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(
        prefix="cotb-analysis-", dir=render_root, ignore_cleanup_errors=True
    ) as temporary:
        temp = Path(temporary)
        source = temp / "figure.tex"
        source.write_text(tex_source, encoding="utf-8", newline="\n")
        run_command(
            [
                pdflatex,
                "-interaction=nonstopmode",
                "-halt-on-error",
                "figure.tex",
            ],
            cwd=temp,
            env=env,
        )
        shutil.copyfile(temp / "figure.pdf", pdf_path)
        prefix = temp / "figure-render"
        run_command(
            [
                pdftocairo,
                "-png",
                "-singlefile",
                "-r",
                "220",
                str(temp / "figure.pdf"),
                str(prefix),
            ],
            cwd=temp,
            env=env,
        )
        shutil.copyfile(prefix.with_suffix(".png"), png_path)
    try:
        render_root.rmdir()
    except OSError:
        pass


def figure_detection_duration(
    strategies: list[dict[str, object]],
) -> str:
    axis_min = math.floor(min(float(row["min_ms"]) for row in strategies) / 100) * 100
    axis_max = math.ceil(max(float(row["max_ms"]) for row in strategies) / 100) * 100
    if axis_max == axis_min:
        axis_max += 100

    def duration_x(value: float) -> float:
        return 8.35 + (value - axis_min) / (axis_max - axis_min) * 6.0

    y_values = {"S0": 3.55, "S1": 2.55, "S2": 1.55}
    lines: list[str] = []
    for row in strategies:
        strategy = str(row["strategy"])
        y = y_values[strategy]
        rate = float(row["detection_rate"])
        bar_width = 5.0 * rate
        count = f"{row['detected_stable']}/{row['valid_denominator']}"
        lines.extend(
            [
                rf"\node[anchor=east,font=\small\bfseries] at (0.62,{y}) {{{strategy}}};",
                rf"\fill[barbg,rounded corners=1pt] (0.82,{y - 0.22}) rectangle (5.82,{y + 0.22});",
                rf"\fill[detect,rounded corners=1pt] (0.82,{y - 0.22}) rectangle ({0.82 + bar_width:.4f},{y + 0.22});",
                rf"\node[anchor=east,font=\scriptsize\bfseries,text=white] at (5.68,{y}) {{{rate * 100:.0f}\% ({count})}};",
            ]
        )

        minimum = float(row["min_ms"])
        median = float(row["median_ms"])
        maximum = float(row["max_ms"])
        lines.extend(
            [
                rf"\node[anchor=east,font=\small\bfseries] at (8.10,{y}) {{{strategy}}};",
                rf"\draw[duration,line width=1.25pt] ({duration_x(minimum):.4f},{y}) -- ({duration_x(maximum):.4f},{y});",
                rf"\draw[duration,line width=.8pt] ({duration_x(minimum):.4f},{y - 0.13}) -- ({duration_x(minimum):.4f},{y + 0.13});",
                rf"\draw[duration,line width=.8pt] ({duration_x(maximum):.4f},{y - 0.13}) -- ({duration_x(maximum):.4f},{y + 0.13});",
                rf"\fill[duration] ({duration_x(median):.4f},{y}) circle (2.3pt);",
                rf"\node[anchor=south,font=\tiny] at ({duration_x(median):.4f},{y + 0.16}) {{{tex_escape(fmt_ms(median))} [{tex_escape(fmt_ms(minimum))}--{tex_escape(fmt_ms(maximum))}]}};",
            ]
        )

    ticks = list(range(int(axis_min), int(axis_max) + 1, 100))
    for tick in ticks:
        x = duration_x(tick)
        lines.extend(
            [
                rf"\draw[grid] ({x:.4f},1.05) -- ({x:.4f},4.08);",
                rf"\node[anchor=north,font=\tiny] at ({x:.4f},0.98) {{{tex_escape(fmt_ms(tick))}}};",
            ]
        )

    return r"""
\documentclass[tikz,border=3pt]{standalone}
\usepackage[T1]{fontenc}
\usepackage[utf8]{inputenc}
\usepackage{lmodern}
\usepackage{tikz}
\pdfinfoomitdate=1
\pdftrailerid{}
\pdfsuppressptexinfo=15
\definecolor{detect}{HTML}{2B6F92}
\definecolor{duration}{HTML}{D06B32}
\definecolor{barbg}{HTML}{E8EEF2}
\definecolor{grid}{HTML}{D9DEE2}
\definecolor{textc}{HTML}{1E2933}
\begin{document}
\begin{tikzpicture}[x=1cm,y=1cm,font=\sffamily,text=textc]
\fill[white] (-0.1,0.05) rectangle (14.7,4.85);
\node[anchor=west,font=\small\bfseries] at (0.0,4.55) {DetecÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o estÃƒÆ’Ã‚Â¡vel em N1--N8};
\node[anchor=west,font=\small\bfseries] at (7.15,4.55) {DuraÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o nominal por estratÃƒÆ’Ã‚Â©gia (n=10)};
\draw[grid,line width=.7pt] (6.45,0.55) -- (6.45,4.55);
""" + "\n".join(lines) + r"""
\node[anchor=north,font=\tiny] at (11.35,0.63) {DuraÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o do processo externo (ms): mediana [mÃƒÆ’Ã‚Â­nimo--mÃƒÆ’Ã‚Â¡ximo]};
\node[anchor=west,font=\tiny] at (0.0,0.24) {N3 invÃƒÆ’Ã‚Â¡lida e excluÃƒÆ’Ã‚Â­da; F1--F8 nÃƒÆ’Ã‚Â£o integram estes denominadores.};
\end{tikzpicture}
\end{document}
"""


def figure_variant_matrix(matrix: list[dict[str, object]]) -> str:
    strategies = ["S0", "S1", "S2"]
    cell_x = {"S0": 3.0, "S1": 4.65, "S2": 6.30}
    lines: list[str] = []
    y_start = 7.1
    for index, row in enumerate(matrix):
        y = y_start - index * 0.72
        variant = str(row["variant"])
        lines.append(
            rf"\node[anchor=east,font=\small\bfseries] at (1.75,{y}) {{{variant}}};"
        )
        for strategy in strategies:
            status = str(row[strategy.lower()])
            if status == "not_applicable":
                color, label = "na", "N/A"
            elif status == "invalid_variant":
                color, label = "invalid", "inv."
            elif status == "detected_stable":
                if bool(row["incremental_s2"]) and strategy == "S2":
                    color, label = "increment", "3/3"
                else:
                    color, label = "detect", "3/3"
            elif status == "survived_stable":
                color, label = "survive", "0/3"
            else:
                color, label = "unstable", "inc."
            x = cell_x[strategy]
            lines.extend(
                [
                    rf"\fill[{color},rounded corners=1.5pt] ({x - 0.58},{y - 0.25}) rectangle ({x + 0.58},{y + 0.25});",
                    rf"\node[font=\scriptsize\bfseries,text=white] at ({x},{y}) {{{label}}};",
                ]
            )

    return r"""
\documentclass[tikz,border=3pt]{standalone}
\usepackage[T1]{fontenc}
\usepackage[utf8]{inputenc}
\usepackage{lmodern}
\usepackage{tikz}
\pdfinfoomitdate=1
\pdftrailerid{}
\pdfsuppressptexinfo=15
\definecolor{detect}{HTML}{2B6F92}
\definecolor{increment}{HTML}{23856D}
\definecolor{survive}{HTML}{A64B4B}
\definecolor{invalid}{HTML}{D06B32}
\definecolor{unstable}{HTML}{8B6AA8}
\definecolor{na}{HTML}{9AA5AE}
\definecolor{textc}{HTML}{1E2933}
\begin{document}
\begin{tikzpicture}[x=1cm,y=1cm,font=\sffamily,text=textc]
\fill[white] (-0.1,0.15) rectangle (8.0,8.35);
\node[anchor=west,font=\small\bfseries] at (0.0,8.05) {Matriz de detecÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o do conjunto prÃƒÆ’Ã‚Â©-registrado N1--N8};
\node[font=\small\bfseries] at (3.0,7.55) {S0};
\node[font=\small\bfseries] at (4.65,7.55) {S1};
\node[font=\small\bfseries] at (6.30,7.55) {S2};
""" + "\n".join(lines) + r"""
\fill[detect,rounded corners=1pt] (0.0,0.78) rectangle (0.34,1.02);
\node[anchor=west,font=\tiny] at (0.44,0.90) {detecÃƒÆ’Ã‚Â§ÃƒÆ’Ã‚Â£o em S0/S1};
\fill[increment,rounded corners=1pt] (3.35,0.78) rectangle (3.69,1.02);
\node[anchor=west,font=\tiny] at (3.79,0.90) {ganho incremental S2};
\fill[na,rounded corners=1pt] (0.0,0.38) rectangle (0.34,0.62);
\node[anchor=west,font=\tiny] at (0.44,0.50) {N/A};
\fill[invalid,rounded corners=1pt] (1.35,0.38) rectangle (1.69,0.62);
\node[anchor=west,font=\tiny] at (1.79,0.50) {invÃƒÆ’Ã‚Â¡lida};
\node[anchor=west,font=\tiny] at (3.35,0.50) {N3 excluÃƒÆ’Ã‚Â­da; F1--F8 ausentes.};
\end{tikzpicture}
\end{document}
"""


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--run-id", default="p1p3-20261103")
    parser.add_argument("--output-dir", type=Path, default=STUDY / "derived")
    parser.add_argument(
        "--figure-dir", type=Path, default=WORKSPACE / "outputs" / "figures"
    )
    parser.add_argument("--tables-only", action="store_true", help="Do not require TeX or Poppler")
    args = parser.parse_args()
    args.output_dir = args.output_dir.resolve()
    args.figure_dir = args.figure_dir.resolve()

    nominal_runs_path = (
        STUDY / "runs" / "nominal" / args.run_id / "nominal-runs.csv"
    )
    variant_runs_path = (
        STUDY / "runs" / "variants" / args.run_id / "variant-runs.csv"
    )
    gate_path = STUDY / "runs" / "gate" / args.run_id / "gate-results.csv"
    catalog_path = STUDY / "variants.csv"
    human_summary_path = STUDY / "results-summary.md"

    source_paths = [
        nominal_runs_path,
        variant_runs_path,
        gate_path,
        catalog_path,
        human_summary_path,
    ]
    for path in source_paths:
        if not path.is_file():
            raise FileNotFoundError(path)

    nominal_runs = read_csv(nominal_runs_path)
    variant_runs = read_csv(variant_runs_path)
    gates = {row["variant"]: row for row in read_csv(gate_path)}
    catalog_rows = read_csv(catalog_path)
    catalog = {row["id"]: row for row in catalog_rows}

    expected_ids = {f"N{index}" for index in range(1, 9)}
    if set(catalog) != expected_ids:
        raise ValueError(f"Catalog must contain exactly N1--N8, got {sorted(catalog)}")
    run_ids = {row["variant"] for row in variant_runs}
    if not run_ids <= expected_ids or any(item.startswith("F") for item in run_ids):
        raise ValueError("Historical F1--F8 or unknown IDs cannot enter this analysis")

    grouped_runs: dict[tuple[str, str], list[dict[str, str]]] = defaultdict(list)
    for row in variant_runs:
        grouped_runs[(row["variant"], row["strategy"])].append(row)
    group_outcome = {
        key: classify_group(rows) for key, rows in sorted(grouped_runs.items())
    }
    invalid_ids = {
        variant
        for (variant, _), outcome in group_outcome.items()
        if outcome == "invalid_variant"
    }
    equivalent_ids = {
        variant
        for (variant, _), outcome in group_outcome.items()
        if outcome == "equivalent_variant"
    }
    excluded_ids = invalid_ids | equivalent_ids

    measured = [row for row in nominal_runs if row["phase"] == "measured"]
    strategy_rows: list[dict[str, object]] = []
    previous_detected: set[str] = set()
    for strategy in ("S0", "S1", "S2"):
        runs = [row for row in measured if row["strategy"] == strategy]
        durations = [int(row["duration_ms"]) for row in runs]
        if len(runs) != 10:
            raise ValueError(f"{strategy}: expected 10 measured nominal runs, got {len(runs)}")
        modal = Counter((row["exit_code"], row["passed"]) for row in runs).most_common(1)[0][0]
        non_modal = sum((row["exit_code"], row["passed"]) != modal for row in runs)
        planned_ids = {item for item, row in catalog.items() if applicable(row, strategy)}
        valid_ids = planned_ids - excluded_ids
        detected_ids = {
            item
            for item in valid_ids
            if group_outcome.get((item, strategy)) == "detected_stable"
        }
        incremental = set() if strategy == "S0" else detected_ids - previous_detected
        median_ms = statistics.median(durations)
        strategy_rows.append(
            {
                "strategy": strategy,
                "composition_tests": int(runs[0]["expected"]),
                "nominal_n": len(runs),
                "median_ms": median_ms,
                "min_ms": min(durations),
                "max_ms": max(durations),
                "non_modal_results": non_modal,
                "planned_denominator": len(planned_ids),
                "valid_denominator": len(valid_ids),
                "detected_stable": len(detected_ids),
                "detection_rate": len(detected_ids) / len(valid_ids) if valid_ids else None,
                "detected_ids": sorted(detected_ids),
                "incremental_gain_count": len(incremental),
                "incremental_gain_ids": sorted(incremental),
            }
        )
        previous_detected = detected_ids

    s1_detected = set(strategy_rows[1]["detected_ids"])
    s2_detected = set(strategy_rows[2]["detected_ids"])
    s2_incremental = s2_detected - s1_detected

    matrix_rows: list[dict[str, object]] = []
    for variant in sorted(catalog, key=lambda item: int(item[1:])):
        row: dict[str, object] = {
            "variant": variant,
            "category": catalog[variant]["category"],
            "primary_category": catalog[variant]["category"].split("/")[0],
            "validity": (
                "invalid_variant"
                if variant in invalid_ids
                else "equivalent_variant"
                if variant in equivalent_ids
                else "valid"
            ),
            "gate": gates[variant]["outcome"],
            "incremental_s2": variant in s2_incremental,
        }
        for strategy in ("S0", "S1", "S2"):
            if not applicable(catalog[variant], strategy):
                row[strategy.lower()] = "not_applicable"
            elif variant in invalid_ids:
                row[strategy.lower()] = "invalid_variant"
            elif variant in equivalent_ids:
                row[strategy.lower()] = "equivalent_variant"
            else:
                row[strategy.lower()] = group_outcome.get(
                    (variant, strategy), "missing_applicable_run"
                )
        matrix_rows.append(row)

    category_rows: list[dict[str, object]] = []
    categories = sorted({str(row["primary_category"]) for row in matrix_rows})
    for strategy in ("S0", "S1", "S2"):
        for category in categories:
            relevant = [
                row
                for row in matrix_rows
                if row["primary_category"] == category
                and row["validity"] == "valid"
                and row[strategy.lower()] != "not_applicable"
            ]
            if not relevant:
                continue
            detected = sum(
                row[strategy.lower()] == "detected_stable" for row in relevant
            )
            category_rows.append(
                {
                    "strategy": strategy,
                    "category": category,
                    "detected_stable": detected,
                    "valid_applicable": len(relevant),
                    "rate": detected / len(relevant),
                    "variant_ids": ";".join(str(row["variant"]) for row in relevant),
                }
            )

    human_summary = human_summary_path.read_text(encoding="utf-8")
    required_summary_fragments = ["S0: 2/2", "S1: 2/2", "S2: 7/7", "N3"]
    missing_fragments = [
        fragment for fragment in required_summary_fragments if fragment not in human_summary
    ]
    if missing_fragments:
        raise ValueError(
            "Derived results conflict with or are absent from results-summary.md: "
            + ", ".join(missing_fragments)
        )

    gate_valid = [gates[item]["outcome"] for item in sorted(expected_ids - excluded_ids)]
    gate_blocked = sum(outcome == "blocked" for outcome in gate_valid)
    summary = {
        "scope": {
            "variant_set": "N1-N8",
            "historical_f1_f8_included": False,
            "invalid_excluded": sorted(invalid_ids),
            "equivalent_excluded": sorted(equivalent_ids),
            "note": "N3 is invalid and excluded from analyzed denominators.",
        },
        "sources_sha256": {
            str(path.relative_to(STUDY)).replace("\\", "/"): sha256(path)
            for path in source_paths
        },
        "strategies": {
            str(row["strategy"]): {
                key: value for key, value in row.items() if key != "strategy"
            }
            for row in strategy_rows
        },
        "incremental_gain_s2_over_s1": {
            "count": len(s2_incremental),
            "variant_ids": sorted(s2_incremental),
        },
        "gate": {
            "blocked_valid": gate_blocked,
            "valid_denominator": len(gate_valid),
            "invalid_inconclusive": sorted(invalid_ids),
            "deployment_performed": False,
        },
        "human_summary_consistency": {
            "checked_fragments": required_summary_fragments,
            "all_present": True,
        },
    }

    args.output_dir.mkdir(parents=True, exist_ok=True)
    strategy_csv = args.output_dir / "strategy-summary.csv"
    matrix_csv = args.output_dir / "variant-matrix.csv"
    category_csv = args.output_dir / "category-summary.csv"
    summary_json = args.output_dir / "analysis-summary.json"

    write_csv(
        strategy_csv,
        [
            {
                **row,
                "detected_ids": ";".join(row["detected_ids"]),
                "incremental_gain_ids": ";".join(row["incremental_gain_ids"]),
            }
            for row in strategy_rows
        ],
        [
            "strategy",
            "composition_tests",
            "nominal_n",
            "median_ms",
            "min_ms",
            "max_ms",
            "non_modal_results",
            "planned_denominator",
            "valid_denominator",
            "detected_stable",
            "detection_rate",
            "detected_ids",
            "incremental_gain_count",
            "incremental_gain_ids",
        ],
    )
    write_csv(
        matrix_csv,
        matrix_rows,
        [
            "variant",
            "category",
            "primary_category",
            "validity",
            "s0",
            "s1",
            "s2",
            "gate",
            "incremental_s2",
        ],
    )
    write_csv(
        category_csv,
        category_rows,
        [
            "strategy",
            "category",
            "detected_stable",
            "valid_applicable",
            "rate",
            "variant_ids",
        ],
    )
    summary_json.write_text(
        json.dumps(summary, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
        newline="\n",
    )

    outputs = [strategy_csv, matrix_csv, category_csv, summary_json]
    if not args.tables_only:
        detection_pdf = args.figure_dir / "cotb_regressoes_deteccao_duracao.pdf"
        detection_png = args.figure_dir / "cotb_regressoes_deteccao_duracao.png"
        matrix_pdf = args.figure_dir / "cotb_regressoes_matriz_n1_n8.pdf"
        matrix_png = args.figure_dir / "cotb_regressoes_matriz_n1_n8.png"
        render_tex(figure_detection_duration(strategy_rows), detection_pdf, detection_png)
        render_tex(figure_variant_matrix(matrix_rows), matrix_pdf, matrix_png)
        outputs.extend([detection_pdf, detection_png, matrix_pdf, matrix_png])

    print(
        json.dumps(
            {
                "outputs": {
                    str(path.relative_to(WORKSPACE)).replace("\\", "/"): sha256(path)
                    for path in outputs
                },
                "f1_f8_included": False,
                "excluded_invalid": sorted(invalid_ids),
            },
            ensure_ascii=False,
            indent=2,
            sort_keys=True,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
