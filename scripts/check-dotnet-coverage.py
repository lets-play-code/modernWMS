#!/usr/bin/env python3
"""Validate coverlet cobertura line coverage for ModernWMS backend."""
from __future__ import annotations

import argparse
import sys
import xml.etree.ElementTree as ET
from pathlib import Path


def read_rate(paths: list[Path]) -> float:
    if len(paths) == 1:
        root = ET.parse(paths[0]).getroot()
        if "line-rate" in root.attrib:
            return float(root.attrib["line-rate"])

        lines_valid = float(root.attrib.get("lines-valid", "0"))
        lines_covered = float(root.attrib.get("lines-covered", "0"))
        if lines_valid <= 0:
            raise ValueError(f"No coverable lines found in {paths[0]}")
        return lines_covered / lines_valid

    merged_lines: dict[tuple[str, str], bool] = {}
    for path in paths:
        root = ET.parse(path).getroot()
        for class_node in root.findall(".//class"):
            filename = class_node.attrib.get("filename", "")
            for line in class_node.findall(".//line"):
                line_number = line.attrib.get("number")
                if not line_number:
                    continue
                key = (filename, line_number)
                covered = int(line.attrib.get("hits", "0")) > 0
                merged_lines[key] = merged_lines.get(key, False) or covered

    if not merged_lines:
        raise ValueError("No coverable lines found in coverage files")
    covered_lines = sum(1 for covered in merged_lines.values() if covered)
    return covered_lines / len(merged_lines)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("coverage", nargs="+", type=Path, help="Path(s) to coverage.cobertura.xml")
    parser.add_argument("--threshold", type=float, default=0.80, help="Required line coverage ratio")
    args = parser.parse_args()

    rate = read_rate(args.coverage)
    percent = rate * 100
    required = args.threshold * 100
    print(f"Backend line coverage: {percent:.2f}% (required: {required:.2f}%)")
    if rate + 1e-9 < args.threshold:
        print(f"Coverage below threshold: {percent:.2f}% < {required:.2f}%", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
