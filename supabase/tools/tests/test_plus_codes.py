import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import plus_codes as pc  # noqa: E402

YAOUNDE = (3.848, 11.5174)


class PlusCodes(unittest.TestCase):
    def test_full_codes_from_google_maps(self):
        # Sino Mart and Marché Elig-Edzoa, as looked up on Google Maps.
        self.assertEqual(pc.to_point("6FMHVGQH+XV"), (3.889937, 11.529687))
        self.assertEqual(pc.to_point("6FMHVGRJ+34"), (3.890188, 11.530312))

    def test_short_code_with_a_city_is_completed_near_the_city(self):
        lat, lng = pc.to_point("VGQH+XQ5, Nv Rte Omnisport, Yaoundé", *YAOUNDE)
        self.assertAlmostEqual(lat, 3.8899, places=3)
        self.assertAlmostEqual(lng, 11.5296, places=3)

    def test_short_code_for_the_market(self):
        lat, lng = pc.to_point("VGQH+WX5, Yaoundé", *YAOUNDE)
        self.assertAlmostEqual(lat, 3.8900, places=3)
        self.assertAlmostEqual(lng, 11.5301, places=3)

    def test_short_code_needs_a_reference(self):
        with self.assertRaises(pc.PlusCodeError):
            pc.to_point("VGQH+XQ5")

    def test_garbage_is_refused(self):
        for bad in ["", "hello", "6FMHVGQH+X!", "123"]:
            with self.assertRaises(pc.PlusCodeError, msg=bad):
                pc.to_point(bad, *YAOUNDE)

    def test_lowercase_and_spaces(self):
        self.assertEqual(pc.to_point(" 6fmhvgqh+xv "), (3.889937, 11.529687))


if __name__ == "__main__":
    unittest.main()
