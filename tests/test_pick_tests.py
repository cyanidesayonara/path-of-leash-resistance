"""tools/pick_tests.py: what a change runs (python3 tests/test_pick_tests.py)."""
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "tools"))
import pick_tests as pt


class Pick(unittest.TestCase):
    def spent(self, items):
        c = pt.costs()
        return sum(c.get(i, pt.WALK_COST) for i in items)

    def test_docs_run_nothing(self):
        self.assertEqual(pt.pick(["README.md", "changelog.d/x.md", "site/index.html", "docs/a.md", ""]), [])

    def test_a_walk_runs_itself_and_its_tests(self):
        got = pt.pick(["systems/vet.gd"])
        self.assertIn("walk vet", got)
        self.assertIn("res://tests/test_vet.gd", got)
        self.assertNotIn("walk beach", got)

    def test_a_shared_script_runs_the_walks_that_use_it(self):
        self.assertIn("walk girona", pt.pick(["systems/girona_art.gd"]))

    def test_the_core_always_runs_and_the_budget_holds(self):
        for change in (["main.gd"], ["systems/vet.gd"], ["autoload/game.gd", "world/level_build.gd"]):
            got = pt.pick(change)
            for c in pt.CORE:
                self.assertIn(c, got)
            self.assertLessEqual(self.spent(got), pt.BUDGET + 60)

    def test_a_changed_test_runs(self):
        self.assertIn("res://tests/test_reial.gd", pt.pick(["tests/test_reial.gd"]))

    def test_a_wide_change_runs_widely(self):
        self.assertGreater(len(pt.pick(["main.gd"])), 40)


if __name__ == "__main__":
    unittest.main()
