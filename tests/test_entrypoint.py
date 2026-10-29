"""Offline checks for central PowerShell dispatch; no tenant access or API calls."""
import json
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]

class TestCentralEntrypoint(unittest.TestCase):
    def test_main_exists_and_imports_module(self):
        main = (ROOT / 'main.ps1').read_text(encoding='utf-8')
        self.assertIn("modules/Migration.Workflow.psm1", main)
        self.assertIn("Start-MigrationConsole", main)
        self.assertIn("Invoke-MigrationStage", main)

    def test_all_workload_helpers_are_dispatched(self):
        module = (ROOT / 'modules/Migration.Workflow.psm1').read_text(encoding='utf-8')
        expected = (
            'Export-GraphInventory.ps1', 'Export-ServiceInventory.ps1',
            'New-IdentityMap.ps1', 'Test-DnsReadiness.ps1',
            'New-CloudTargetUsers.ps1', 'Invoke-Ctim.ps1',
            'Test-TargetMailboxReadiness.ps1', 'Invoke-NativeOrchestrator.ps1',
            'assess.py',
        )
        for helper in expected:
            with self.subTest(helper=helper):
                self.assertIn(helper, module)
                directory = 'tools' if helper.endswith('.py') else 'scripts'
                self.assertTrue((ROOT / directory / helper).is_file())

    def test_execute_gates_cannot_be_implicitly_enabled(self):
        main = (ROOT / 'main.ps1').read_text(encoding='utf-8')
        module = (ROOT / 'modules/Migration.Workflow.psm1').read_text(encoding='utf-8')
        self.assertIn("$current.Execute = $false", module)
        self.assertIn("$current.ApprovalPhrase = $null", module)
        self.assertIn("CREATE-MAILUSERS:", module)
        self.assertIn("CTIM:", module)
        self.assertIn("APPROVED:", module)
        self.assertIn("[switch]$Execute", main)
        self.assertIn("AllReadOnly", module)

    def test_documented_sample_config_is_valid_json(self):
        cfg = json.loads((ROOT / 'config/sample.json').read_text(encoding='utf-8'))
        self.assertNotEqual(cfg['sourceTenantId'], cfg['targetTenantId'])
        self.assertIn('onmicrosoft.com', cfg['targetStagingDomain'])
        self.assertIn('sourceSPOAdminUrl', cfg)
        self.assertIn('targetSPOAdminUrl', cfg)

if __name__ == '__main__':
    unittest.main()
