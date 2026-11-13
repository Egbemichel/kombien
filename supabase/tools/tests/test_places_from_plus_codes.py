import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import places_from_plus_codes as ppc  # noqa: E402

EXISTING = [
    {"city": "Yaoundé", "name": "Sino Mart", "aliases": [], "at": (3.889937, 11.529687)},
    {"city": "Yaoundé", "name": "Carrefour Messassi", "aliases": [], "at": (3.9300, 11.5000)},
]


def row(**kw):
    base = {"name": "", "city": "Yaoundé", "plus_code": "", "kind": "", "aliases": "", "query": ""}
    base.update(kw)
    return base


class Build(unittest.TestCase):
    def test_a_new_place_is_kept_with_its_kind_and_aliases(self):
        keep, skipped = ppc.build(
            [row(name="Marché Elig-Edzoa", plus_code="6FMHVGRJ+34", kind="market",
                 aliases="Marche Elig Edzoa; Marché Elig-Dzoa", query="marche elig edzoa")],
            EXISTING)
        self.assertEqual(skipped, [])
        self.assertEqual(keep[0]["kind"], "amenity=marketplace")
        self.assertEqual(keep[0]["aliases"], ["Marche Elig Edzoa", "Marché Elig-Dzoa"])
        self.assertEqual(keep[0]["at"], (3.890188, 11.530312))

    def test_rows_without_a_code_are_left_for_later(self):
        keep, skipped = ppc.build([row(name="Not yet")], EXISTING)
        self.assertEqual((keep, skipped), ([], []))

    def test_known_places_are_skipped_even_with_another_spelling(self):
        _, skipped = ppc.build(
            [row(name="sino  mart", plus_code="6FMHVGQH+XV")], EXISTING)
        self.assertIn("already in Kombien", skipped[0][2])

    def test_outside_the_city_and_bad_codes_are_explained(self):
        _, skipped = ppc.build(
            [row(name="Place Alpha", plus_code="6GGGGGGG+22"), row(name="Place Beta", plus_code="hello")],
            EXISTING)
        self.assertIn("outside", skipped[0][2])
        self.assertIn("Plus Code", skipped[1][2])

    def test_the_same_place_twice_in_the_file_counts_once(self):
        keep, skipped = ppc.build(
            [row(name="Dup Place", plus_code="6FMHVGRJ+34"),
             row(name="dup place", plus_code="6FMHVGRJ+34")], EXISTING)
        self.assertEqual(len(keep), 1)
        self.assertEqual(skipped[0][2], "listed twice")

    def test_the_migration_is_idempotent_and_clears_the_missing_row(self):
        keep, _ = ppc.build(
            [row(name="O'Neil's", plus_code="6FMHVGRJ+34", query="oneils")], EXISTING)
        sql = ppc.migration(keep, "x.csv")
        self.assertIn("on conflict (city_id, name) do nothing", sql)
        self.assertIn("'O''Neil''s'", sql)  # quotes are escaped
        self.assertIn("delete from public.search_misses where query in ('oneils')", sql)
        self.assertIn("'manual'", sql)


if __name__ == "__main__":
    unittest.main()
