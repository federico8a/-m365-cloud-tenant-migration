import csv
import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
from assess import assess


class ReadinessTests(unittest.TestCase):
    def setUp(self):
        self.workspace = tempfile.TemporaryDirectory()
        root = Path(self.workspace.name)
        self.source = root / "source"
        self.target = root / "target"
        self.source.mkdir()
        self.target.mkdir()
        self.mapping = root / "map.csv"
        for folder, user in ((self.source, {"id": "src-1", "onPremisesSyncEnabled": False}),
                             (self.target, {"id": "dst-1"})):
            (folder / "users.json").write_text(json.dumps([user]))
            (folder / "collection-errors.json").write_text("[]")
        with self.mapping.open("w", newline="") as file:
            writer = csv.DictWriter(file, fieldnames=["sourceId", "sourceUPN", "targetUPN", "targetId", "approved"])
            writer.writeheader()
            writer.writerow({"sourceId": "src-1", "sourceUPN": "a@source.com", "targetUPN": "a@target.com", "targetId": "dst-1", "approved": "true"})

    def tearDown(self):
        self.workspace.cleanup()

    def test_assessment_is_never_automatic_go(self):
        result = assess(self.source, self.target, self.mapping)
        self.assertEqual(result["status"], "HUMAN_GATES_REQUIRED")
        self.assertFalse(result["canMigrateAutomatically"])

    def test_hybrid_identity_fails(self):
        (self.source / "users.json").write_text(json.dumps([{"id": "src-1", "onPremisesSyncEnabled": True}]))
        result = assess(self.source, self.target, self.mapping)
        self.assertEqual(result["status"], "BLOCKED")

    def test_unknown_target_fails(self):
        (self.target / "users.json").write_text("[]")
        self.assertEqual(assess(self.source, self.target, self.mapping)["status"], "BLOCKED")

    def test_inventory_failure_fails(self):
        (self.source / "collection-errors.json").write_text('[{"workload":"intune"}]')
        self.assertEqual(assess(self.source, self.target, self.mapping)["status"], "BLOCKED")


if __name__ == "__main__":
    unittest.main()
