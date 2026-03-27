import unittest
from app.services.refraction_service import RefractionService

class TestRefractionService(unittest.TestCase):

    def test_calculate_physical_size_mm(self):
        # 1080px width on a 400 ppi screen
        # inch = 1080 / 400 = 2.7 inches
        # mm = 2.7 * 25.4 = 68.58 mm
        mm = RefractionService.calculate_physical_size_mm(1080, 400.0)
        self.assertAlmostEqual(mm, 68.58, places=2)

    def test_calculate_acuity_normal(self):
        # Smallest row 8 (20/20), no missed chars
        snellen, decimal = RefractionService.calculate_acuity(8, 0)
        self.assertEqual(snellen, "20/20")
        self.assertEqual(decimal, 1.0)

    def test_calculate_acuity_with_misses(self):
        # Smallest row 8, but missed 3 chars (threshold is 2)
        # Should drop to row 7 (20/25)
        snellen, decimal = RefractionService.calculate_acuity(8, 3)
        self.assertEqual(snellen, "20/25")
        self.assertEqual(decimal, 20.0 / 25.0)

    def test_calculate_acuity_bounds(self):
        # Even if they read row 1 and miss 3 chars, row drops to 0 -> bounds to 1 (20/200)
        snellen, decimal = RefractionService.calculate_acuity(1, 3)
        self.assertEqual(snellen, "20/200")
        self.assertEqual(decimal, 0.1)

    def test_classify_vision(self):
        cat, rec = RefractionService.classify_vision(1.0)
        self.assertEqual(cat, "Normal Vision")

        cat, rec = RefractionService.classify_vision(0.8)
        self.assertEqual(cat, "Mild Impairment")

        cat, rec = RefractionService.classify_vision(0.3)
        self.assertEqual(cat, "Visual Impairment")

if __name__ == '__main__':
    unittest.main()
