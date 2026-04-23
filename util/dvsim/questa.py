# Copyright lowRISC contributors (OpenTitan project).
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

"""EDA tool plugin providing Questa support to DVSim."""

import re
from collections.abc import Mapping, Sequence
from pathlib import Path

__all__ = ("Questa",)


class Questa:
    """Implement Questa tool support."""

    @staticmethod
    def get_cov_summary_table(cov_report_path: Path) -> tuple[Sequence[Sequence[str]], str]:
        """Get a coverage summary from a vcover text report."""
        metrics = []
        values = []
        cov_total = None

        with Path(cov_report_path).open() as buf:
            for line in buf:
                # vcover report produces lines like:
                # Covergroup Coverage:  85.71% (6/7)
                m = re.match(
                    r"^\s*([\w /]+Coverage):\s*(\d+\.?\d*)\s*%",
                    line,
                    re.IGNORECASE,
                )
                if m:
                    label = m.group(1).strip()
                    value = f"{m.group(2)} %"
                    metrics.append(label)
                    values.append(value)
                    if cov_total is None:
                        cov_total = value

        if not metrics:
            msg = f"Coverage data not found in {cov_report_path}!"
            raise SyntaxError(msg)

        return [metrics, values], cov_total

    @staticmethod
    def get_job_runtime(log_text: Sequence[str]) -> tuple[float, str]:
        """Return the job runtime from a qrun/vsim log.

        Questa logs elapsed wall-clock time as:
          End time: HH:MM:SS on ..., Elapsed time: H:MM:SS
        """
        pattern = r"Elapsed time:\s*(\d+):(\d+):(\d+)"
        for line in reversed(log_text):
            m = re.search(pattern, line)
            if m:
                t = int(m.group(1)) * 3600 + int(m.group(2)) * 60 + int(m.group(3))
                return float(t), "s"

        msg = "Job runtime not found in the log."
        raise RuntimeError(msg)

    @staticmethod
    def get_simulated_time(log_text: Sequence[str]) -> tuple[float, str]:
        """Return the simulated time from a vsim run log.

        vsim prints the simulation end time as:
          # $finish called at time : 12345 ns
        or:
          # ** Note: $finish : <path>(<line>) at time: 12345 ns
        """
        patterns = [
            r"#\s+\$finish called at time\s*:\s*(\d+\.?\d*)\s*(.?[sS])",
            r"#.*\$finish.*at time:\s*(\d+\.?\d*)\s*(.?[sS])",
        ]
        for line in reversed(log_text):
            for pat in patterns:
                m = re.search(pat, line)
                if m:
                    return float(m.group(1)), m.group(2).lower()

        msg = "Simulated time not found in the log."
        raise RuntimeError(msg)

    @staticmethod
    def get_coverage_metrics(raw_metrics: Mapping[str, float | None] | None):
        """Get a CoverageMetrics model from raw Questa coverage data."""
        from dvsim.sim.data import CodeCoverageMetrics, CoverageMetrics  # type: ignore
        if raw_metrics is None:
            return CoverageMetrics(code=None, assertion=None, functional=None)

        return CoverageMetrics(
            functional=raw_metrics.get("covergroup"),
            assertion=raw_metrics.get("assertion"),
            code=CodeCoverageMetrics(
                block=None,
                line_statement=raw_metrics.get("statement"),
                branch=raw_metrics.get("branch"),
                condition_expression=raw_metrics.get("condition"),
                toggle=raw_metrics.get("toggle"),
                fsm=raw_metrics.get("fsm"),
            ),
        )
