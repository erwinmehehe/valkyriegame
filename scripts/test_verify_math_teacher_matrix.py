#!/usr/bin/env python3
"""Contract tests: 76-row source sync is NOT a teacher-approval substitute."""
import csv
from pathlib import Path
import sys
from tempfile import TemporaryDirectory
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parent))
import verify_math_teacher_matrix as matrix


class TeacherMatrixIntegrityTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.catalog = matrix.CATALOG.read_text(encoding="utf-8")
        cls.foundation = matrix.FOUNDATION.read_text(encoding="utf-8")
        cls.worksheet = matrix.MATRIX.read_text(encoding="utf-8")

    def validated(self, catalog=None, foundation=None, worksheet=None):
        return matrix.validate(
            self.catalog if catalog is None else catalog,
            self.foundation if foundation is None else foundation,
            self.worksheet if worksheet is None else worksheet,
        )

    def test_all_76_source_skills_are_in_order_and_have_stable_ids(self):
        rows = self.validated()
        self.assertEqual(len(rows), 76)
        self.assertEqual([row.order for row in rows], list(range(1, 77)))
        self.assertEqual(len({row.skill_id for row in rows}), 76)
        self.assertEqual(
            {band: sum(row.band == band for row in rows) for band in matrix.BANDS.values()},
            {"K2 readiness": 14, "Kindergarten": 17, "Grade 1": 32, "Grade 2": 13},
        )
        self.assertEqual(rows[0].skill_id, "math.quantityRecognition")
        self.assertEqual(rows[-1].skill_id, "math.time.clockFiveMinutes")

    def test_missing_or_reordered_teacher_rows_fail(self):
        without_last = "\n".join(
            line for line in self.worksheet.splitlines()
            if not line.startswith("| 76 |")
        )
        with self.assertRaisesRegex(matrix.MatrixError, "75 rows"):
            self.validated(worksheet=without_last)

        moved = self.worksheet.replace("| 12 |", "| 99 |", 1)
        with self.assertRaisesRegex(matrix.MatrixError, "1..76"):
            self.validated(worksheet=moved)

    def test_changed_title_symbol_and_strand_fail(self):
        title = self.worksheet.replace(
            "Recognize Quantities", "Recognize Every Quantity", 1
        )
        with self.assertRaisesRegex(matrix.MatrixError, "row 1 drift"):
            self.validated(worksheet=title)

        symbol = self.worksheet.replace(
            "MathSkills.quantity", "MathSkills.counting", 1
        )
        with self.assertRaisesRegex(matrix.MatrixError, "row 1 drift"):
            self.validated(worksheet=symbol)

        strand = self.worksheet.replace(
            "| numberSense | Not reviewed |",
            "| addition | Not reviewed |", 1
        )
        with self.assertRaisesRegex(matrix.MatrixError, "row 1 drift"):
            self.validated(worksheet=strand)

    def test_grade_or_raw_id_drift_fails(self):
        grade = self.worksheet.replace(
            "| K2 readiness | numberSense | Not reviewed |",
            "| Grade 2 | numberSense | Not reviewed |", 1
        )
        with self.assertRaisesRegex(matrix.MatrixError, "band drift"):
            self.validated(worksheet=grade)

        raw_id = self.worksheet.replace(
            "math.time.clockFiveMinutes", "math.time.clockHalfHour", 1
        )
        with self.assertRaisesRegex(matrix.MatrixError, "SkillID drift"):
            self.validated(worksheet=raw_id)

    def test_grade_set_overlap_and_id_collision_fail(self):
        duplicate_band = self.catalog.replace(
            "        MathSkills.clockHour\n", "        MathSkills.quantity\n", 1
        )
        with self.assertRaisesRegex(matrix.MatrixError, "multiple grade bands"):
            self.validated(catalog=duplicate_band)

        duplicate_id = self.catalog.replace(
            'rawValue: "math.numberSense.oneToOne10"',
            'rawValue: "math.quantityRecognition"', 1
        )
        with self.assertRaisesRegex(matrix.MatrixError, "Duplicate underlying SkillID"):
            self.validated(catalog=duplicate_id)

    def test_csv_keeps_human_evidence_blank_and_never_overwrites(self):
        rows = self.validated()
        output = matrix.csv_rows(rows)
        self.assertEqual(len(output), 76)
        self.assertEqual(list(output[0].keys()), list(matrix.CSV_COLUMNS))
        human_fields = matrix.CSV_COLUMNS[7:]
        self.assertTrue(all(
            all(row[field] == "" for field in human_fields) for row in output
        ))
        self.assertEqual({row["worksheet_verdict"] for row in output}, {"Not reviewed"})

        with TemporaryDirectory() as directory:
            destination = Path(directory) / "teacher-review.csv"
            matrix.write_csv(rows, destination)
            with destination.open(newline="", encoding="utf-8") as handle:
                read = list(csv.DictReader(handle))
            self.assertEqual(read, output)
            with self.assertRaises(FileExistsError):
                matrix.write_csv(rows, destination)


if __name__ == "__main__":
    unittest.main()
