#!/usr/bin/env python3
"""Fail closed when the unapproved 76-skill teacher worksheet drifts from Swift.

This is a catalog-integrity check and blank worksheet export. It does not
validate instruction, evidence quality, MATATAG mapping or approval.
"""
from __future__ import annotations

import argparse
import csv
from dataclasses import dataclass
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "ValkyrieLearn/Curriculum/Math/MathSkillGraphV2.swift"
FOUNDATION = ROOT / "ValkyrieLearn/Curriculum/Math/MathFoundation.swift"
MATRIX = ROOT / "docs/MATH_TEACHER_REVIEW_MATRIX.md"

BANDS = {
    "k2Readiness": "K2 readiness",
    "kindergarten": "Kindergarten",
    "grade1": "Grade 1",
    "grade2": "Grade 2",
}
EXPECTED_SKILLS = 76

CSV_COLUMNS = (
    "order", "skill_symbol", "skill_id", "activity", "internal_band",
    "strand", "worksheet_verdict", "competency_classification",
    "deped_source_url", "deped_competency_excerpt", "singapore_reference_url",
    "child_action_observed", "pre_reader_language_checked",
    "untouched_no_evidence", "incomplete_no_evidence",
    "wrong_incorrect", "undo_and_correct", "hint_scored_assisted",
    "completion_evidence_immutable", "offline_restore_checked",
    "native_screenshot_and_sha", "reviewer", "review_date",
    "review_decision_and_gaps",
)


class MatrixError(ValueError):
    """The index cannot be trusted to represent the current Swift catalog."""


@dataclass(frozen=True)
class SkillRow:
    order: int
    symbol: str
    skill_id: str
    title: str
    band: str
    strand: str
    worksheet_verdict: str


def _descriptor_catalog(source: str) -> list[tuple[int, str, str, str]]:
    start = "public static let descriptors: [MathSkillDescriptor] = ["
    end = "public static func graph()"
    if source.count(start) != 1 or source.count(end) != 1:
        raise MatrixError("Cannot locate the unique Swift descriptor catalog")
    block = source.split(start, 1)[1].split(end, 1)[0]
    matches = re.findall(
        r'\.init\s*\(\s*id:\s*MathSkills\.(\w+)\s*,\s*'
        r'strand:\s*\.(\w+)\s*,\s*title:\s*"([^"]+)"\s*,\s*'
        r'developmentalOrder:\s*(\d+)',
        block, re.S,
    )
    catalog = [(int(order), symbol, strand, title)
               for symbol, strand, title, order in matches]
    orders = [row[0] for row in catalog]
    if len(catalog) != EXPECTED_SKILLS or sorted(orders) != list(range(1, EXPECTED_SKILLS + 1)):
        raise MatrixError(
            f"Expected {EXPECTED_SKILLS} uniquely ordered Swift descriptors; got {len(catalog)}"
        )
    if len({row[1] for row in catalog}) != len(catalog):
        raise MatrixError("Duplicate MathSkills symbols in Swift descriptors")
    return sorted(catalog)


def _canonical_ids(catalog_source: str, foundation_source: str) -> dict[str, str]:
    pattern = r'(?:public\s+)?static\s+let\s+(\w+)\s*=\s*SkillID\(\s*rawValue:\s*"([^"]+)"\s*\)'
    values: dict[str, str] = {}
    for symbol, skill_id in re.findall(pattern, foundation_source + "\n" + catalog_source):
        if symbol in values and values[symbol] != skill_id:
            raise MatrixError(f"Conflicting definitions for MathSkills.{symbol}")
        values[symbol] = skill_id
    if len(set(values.values())) != len(values):
        raise MatrixError("Duplicate underlying SkillID raw values found in Swift")
    return values


def _grade_bands(source: str) -> dict[str, str]:
    mapping: dict[str, str] = {}
    for token, label in BANDS.items():
        match = re.search(
            r'private\s+static\s+let\s+' + token
            + r'\s*:\s*Set<SkillID>\s*=\s*\[(.*?)\]',
            source, re.S,
        )
        if not match:
            raise MatrixError(f"Missing grade band set: {token}")
        symbols = re.findall(r'MathSkills\.(\w+)', match.group(1))
        if not symbols:
            raise MatrixError(f"Grade band has no symbols: {token}")
        for symbol in symbols:
            if symbol in mapping:
                raise MatrixError(f"MathSkills.{symbol} belongs to multiple grade bands")
            mapping[symbol] = label
    return mapping


def _worksheet_rows(markdown: str) -> list[tuple[int, str, str | None, str, str, str, str]]:
    rows: list[tuple[int, str, str | None, str, str, str, str]] = []
    for line in markdown.splitlines():
        if not re.match(r'^\|\s*\d+\s*\|', line):
            continue
        fields = [value.strip() for value in line.strip().strip("|").split("|")]
        if len(fields) != 6:
            raise MatrixError(f"Expected 6 columns in teacher worksheet row: {line}")
        order, source, title, band, strand, verdict = fields
        match = re.fullmatch(r'\x60MathSkills\.(\w+)\x60(?:\s+\(\x60([^\x60]+)\x60\))?', source)
        if not match:
            raise MatrixError(f"Invalid authoritative Swift symbol in worksheet row {order}: {source}")
        if not verdict:
            raise MatrixError(f"Missing explicit review status in worksheet row {order}")
        rows.append((int(order), match.group(1), match.group(2),
                     title, band, strand, verdict))
    return rows


def validate(catalog_source: str, foundation_source: str, markdown: str) -> list[SkillRow]:
    """Compare every source-backed field; never infer a teacher decision."""
    descriptors = _descriptor_catalog(catalog_source)
    ids = _canonical_ids(catalog_source, foundation_source)
    grade_bands = _grade_bands(catalog_source)
    worksheet = _worksheet_rows(markdown)
    symbols = {descriptor[1] for descriptor in descriptors}
    if set(grade_bands) != symbols:
        raise MatrixError(
            "Swift grade bands do not match the 76 descriptor symbols: "
            f"missing={sorted(symbols - set(grade_bands))}, "
            f"unexpected={sorted(set(grade_bands) - symbols)}"
        )
    if not symbols.issubset(ids):
        raise MatrixError(f"Unresolved Swift SkillIDs: {sorted(symbols - set(ids))}")
    if len(worksheet) != EXPECTED_SKILLS:
        raise MatrixError(
            f"Teacher worksheet has {len(worksheet)} rows; expected {EXPECTED_SKILLS}"
        )
    if [row[0] for row in worksheet] != list(range(1, EXPECTED_SKILLS + 1)):
        raise MatrixError("Worksheet rows must be 1..76 in source developmental order")

    checked: list[SkillRow] = []
    for expected, actual in zip(descriptors, worksheet):
        order, symbol, strand, title = expected
        row_order, row_symbol, annotated_id, row_title, band, row_strand, verdict = actual
        if (row_order, row_symbol, row_title, row_strand) != (order, symbol, title, strand):
            raise MatrixError(
                f"Worksheet row {order} drift: expected {symbol!r}, {title!r}, {strand!r}"
            )
        if band != grade_bands[symbol]:
            raise MatrixError(
                f"Worksheet band drift at MathSkills.{symbol}: "
                f"{band!r} != {grade_bands[symbol]!r}"
            )
        if annotated_id is not None and annotated_id != ids[symbol]:
            raise MatrixError(
                f"Worksheet SkillID drift at MathSkills.{symbol}: {annotated_id!r}"
            )
        checked.append(SkillRow(order, symbol, ids[symbol], title, band, strand, verdict))
    return checked


def csv_rows(rows: list[SkillRow]) -> list[dict[str, str]]:
    """Keep approval and observable-evidence fields blank for human review."""
    output: list[dict[str, str]] = []
    for row in rows:
        record = dict.fromkeys(CSV_COLUMNS, "")
        record.update({
            "order": str(row.order),
            "skill_symbol": f"MathSkills.{row.symbol}",
            "skill_id": row.skill_id,
            "activity": row.title,
            "internal_band": row.band,
            "strand": row.strand,
            "worksheet_verdict": row.worksheet_verdict,
        })
        output.append(record)
    return output


def write_csv(rows: list[SkillRow], path: Path) -> None:
    """Never overwrite a teacher's local annotated worksheet."""
    with path.open("x", newline="", encoding="utf-8") as file:
        writer = csv.DictWriter(file, fieldnames=CSV_COLUMNS)
        writer.writeheader()
        writer.writerows(csv_rows(rows))


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--export-csv", type=Path, metavar="PATH",
        help="Create a teacher-review CSV; refuses to overwrite an existing file",
    )
    args = parser.parse_args(argv)
    try:
        rows = validate(
            CATALOG.read_text(encoding="utf-8"),
            FOUNDATION.read_text(encoding="utf-8"),
            MATRIX.read_text(encoding="utf-8"),
        )
        if args.export_csv is not None:
            write_csv(rows, args.export_csv)
            print(f"Created {args.export_csv} with {len(rows)} rows and blank approval fields.")
    except (MatrixError, FileExistsError, OSError) as error:
        print(f"FAIL Math teacher-review catalog integrity: {error}", file=sys.stderr)
        return 1
    print(
        f"PASS {len(rows)} Swift Math skills match the teacher-review index; "
        "no educator, MATATAG or device approval inferred."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
