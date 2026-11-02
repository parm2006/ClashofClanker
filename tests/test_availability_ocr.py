import sys
import unittest
from pathlib import Path

import cv2
import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from vision_hook import read_fraction_ocr


class AvailabilityOCRTests(unittest.TestCase):
    def test_screenshot_counts_with_scale_and_contrast_changes(self):
        fixtures = Path(__file__).parent / "fixtures" / "availability"
        for mode, filename, expected in [
            ("builders", "builders_3_of_6.png", (3, 6)),
            ("lab", "lab_0_of_2.png", (0, 2)),
        ]:
            image = cv2.imread(str(fixtures / filename))
            self.assertIsNotNone(image)
            variants = {
                "original": image,
                "small": cv2.resize(image, None, fx=0.75, fy=0.75),
                "dim": cv2.convertScaleAbs(image, alpha=0.55, beta=25),
                "low_contrast": cv2.convertScaleAbs(image, alpha=0.35, beta=75),
            }
            for variant, pixels in variants.items():
                with self.subTest(mode=mode, variant=variant):
                    result = read_fraction_ocr(pixels, mode)
                    self.assertIsNotNone(result)
                    self.assertEqual((result["free"], result["total"]), expected)
                    self.assertEqual(set(np.unique(result["mask"])), {0, 255})

    def test_empty_badges_do_not_report_available_builders(self):
        for mode in ("builders", "lab"):
            for value in (0, 80, 255):
                with self.subTest(mode=mode, value=value):
                    self.assertIsNone(read_fraction_ocr(np.full((40, 80, 3), value, np.uint8), mode))


if __name__ == "__main__":
    unittest.main()
