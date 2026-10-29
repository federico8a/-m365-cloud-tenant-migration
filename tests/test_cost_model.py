import sys
import unittest
from decimal import Decimal
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'tools'))
from cost_model import estimate
class CostModelTests(unittest.TestCase):
    def test_known_two_month_overlap_and_unquoted_addon(self):
        r=estimate(150,2,'Business Premium',450)
        self.assertEqual(r['destinationLicenseOverlap'],'8940.00')
        self.assertIsNone(r['ctudmOneTimeTotalCAD'])
        self.assertEqual(r['nativeSharePoint100GbUnitsIfEAEligible'],5)
    def test_quote_addon_without_double_count(self):
        r=estimate(2,1,'Business Basic',0,Decimal('22'))
        self.assertEqual(r['partialKnownTotalCAD'],'63.00')
    def test_zero_users_invalid(self):
        with self.assertRaises(ValueError):estimate(0,1,'Business Premium')
if __name__ == '__main__':unittest.main()
