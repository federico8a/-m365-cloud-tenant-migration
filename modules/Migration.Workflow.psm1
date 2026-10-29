#Requires -Version 7.0
# Module invoked exclusively by ../main.ps1. Helpers stay independently runnable for debugging.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-WorkflowPath {
    param([Parameter(Mandatory)][string]$RepoRoot, [Parameter(Mandatory)][string]$Path)
    if ([System.IO.Path]::IsPathRooted($Path)) { return [System.IO.Path]::GetFullPath($Path) }
    return [System.IO.Path]::GetFullPath((Join-Path $RepoRoot $Path))
}

function Get-WorkflowConfig {
    param([hashtable]$Options)
    $path = Resolve-WorkflowPath -RepoRoot $Options.RepoRoot -Path $Options.ConfigPath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Configuration missing: $path. Run: Copy-Item ./config/sample.json ./config/local.json and configure real tenant IDs."
    }
    $c = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json -AsHashtable
    $source = [guid]::Empty
    $target = [guid]::Empty
    if (-not [guid]::TryParse([string]$c.sourceTenantId, [ref]$source) -or $source -eq [guid]::Empty) { throw 'Invalid sourceTenantId.' }
    if (-not [guid]::TryParse([string]$c.targetTenantId, [ref]$target) -or $target -eq [guid]::Empty) { throw 'Invalid targetTenantId.' }
    if ($source -eq $target) { throw 'Source and target tenant IDs must differ.' }
    if ([string]$c.targetStagingDomain -notmatch '^[A-Za-z0-9.-]+\.onmicrosoft\.com$') { throw 'targetStagingDomain must be a target *.onmicrosoft.com domain.' }
    return $c
}

function Invoke-WorkflowHelper {
    param([hashtable]$Options, [Parameter(Mandatory)][string]$Script, [string[]]$Arguments = @())
    $helper = Resolve-WorkflowPath -RepoRoot $Options.RepoRoot -Path "scripts/$Script"
    if (-not (Test-Path -LiteralPath $helper -PathType Leaf)) { throw "Helper script missing: $helper" }
    # A fresh PowerShell process per helper isolates Microsoft Graph/Exchange/CTIM sign-ins.
    $pwsh = Get-Command pwsh -ErrorAction Stop
    Write-Host "`n>>> $Script (separate session)" -ForegroundColor Cyan
    & $pwsh.Source -NoProfile -File $helper @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Helper $Script failed with exit code $LASTEXITCODE. Workflow stopped." }
}

function Invoke-WorkflowPython {
    param([hashtable]$Options, [Parameter(Mandatory)][string]$Script, [string[]]$Arguments)
    $python = Get-Command python3 -ErrorAction SilentlyContinue
    if (-not $python) { $python = Get-Command python -ErrorAction Stop }
    $path = Resolve-WorkflowPath -RepoRoot $Options.RepoRoot -Path "tools/$Script"
    & $python.Source $path @Arguments
    if ($LASTEXITCODE -ne 0) { throw "Python helper $Script returned exit code $LASTEXITCODE." }
}

function Get-CurrentMapping {
    param([hashtable]$Options, [switch]$PreferTarget)
    if ($Options.MappingCsv) { return (Resolve-WorkflowPath $Options.RepoRoot $Options.MappingCsv) }
    $target = Resolve-WorkflowPath $Options.RepoRoot 'output/identity-map-target.csv'
    if ($PreferTarget -and (Test-Path -LiteralPath $target)) { return $target }
    return (Resolve-WorkflowPath $Options.RepoRoot 'output/identity-map.csv')
}

function Get-MigrationPlan {
    @'
CLOUD-ONLY TENANT A -> B MIGRATION / CENTRAL WORKFLOW
----------------------------------------------------
  1. Prerequisites      Inspect modules, credentials/roles, commercial licenses, holds.
  2. AllReadOnly        Graph inventories A & B; optionally service inventories; map;
                       offline assessment; DNS audit. Safe, NO target writes.
  3. IdentityMap        Human reviews and approves unique IDs/source SMTP.
  4. TargetUsers        Preview first; -Execute + EXACT approval creates unlicensed
                       target MailUsers. Protect target from mailbox/OneDrive provision.
  5. Ctim               Run official stages with source/target role in fresh sessions.
  6. MailboxReadiness   Confirm target MailUsers + Exchange GUIDs, NO target mailboxes.
  7. MigrationPreview   Render native Graph-beta migration job; no API mutation.
  8. MigrationCreate    Approval-gated job submission (NOT proof of completion).
  9. MigrationValidate  Approval-gated migration batch validation.
 10. MigrationStatus    Read-only job status query.
 11. MigrationStart     Approval-gated operation after validated job and change control.
 12. DNS / custom domain transfer only at APPROVED cutover, never discovery.
 13. MANUAL WORKSTREAMS SharePoint/Teams workspaces/Intune/devices/enterprise apps/
                       Purview/Power Platform/phone/Fabric remain separate gates.

IMPORTANT: There is deliberately NO one-click production 'Migrate Everything'. Native
M365 APIs do not support complete tenant migration. Follow docs/RUNBOOK.md and
WORKLOAD-MATRIX.md; do not license target Exchange/OneDrive early.
'@
}

function Assert-InventoryComplete {
    param([hashtable]$Options, [ValidateSet('source','target')][string]$Side)
    $dir = Resolve-WorkflowPath $Options.RepoRoot "output/$Side"
    $manifest = Join-Path $dir '_manifest.json'
    if (-not (Test-Path -LiteralPath $manifest)) { throw "Missing $Side manifest: $manifest" }
    $obj = Get-Content -LiteralPath $manifest -Raw | ConvertFrom-Json
    if ($obj.failedCollections -gt 0) { throw "INCOMPLETE: $Side inventory has $($obj.failedCollections) failed collections. Check local collection-errors.json. Do not interpret missing data as empty." }
}

function Test-WorkflowPrerequisites {
    $modules = @('Microsoft.Graph.Authentication','Microsoft.Graph.Beta.Migrations','ExchangeOnlineManagement','MicrosoftTeams','Microsoft.Online.SharePoint.PowerShell','CrossTenantIdentityMapping')
    foreach ($name in $modules) {
        $present = [bool](Get-Module -ListAvailable -Name $name)
        $status = if ($present) {'Available'} else {'Missing / may be required for selected stage'}
        Write-Host ("{0,-48} {1}" -f $name, $status)
    }
    foreach ($name in @('pwsh','python3')) {
        Write-Host ("{0,-48} {1}" -f $name, [bool](Get-Command $name -ErrorAction SilentlyContinue))
    }
    Write-Warning 'These checks do NOT verify tenant administrative roles, migration SKU purchases, customer approvals, data residency, or supported migration eligibility. See docs/LICENSING-COSTS.md and docs/REQUIREMENTS.md.'
}

function Invoke-MigrationStage {
    [CmdletBinding()]
    param([Parameter(Mandatory)][hashtable]$Options)
    $stage = [string]$Options.Stage
    if ($stage -eq 'Plan') { Get-MigrationPlan; return }
    if ($stage -eq 'Prerequisites') { Test-WorkflowPrerequisites; Get-MigrationPlan; return }
    $c = Get-WorkflowConfig -Options $Options
    $root = $Options.RepoRoot
    $configPath = Resolve-WorkflowPath $root $Options.ConfigPath
    $source = [string]$c.sourceTenantId
    $target = [string]$c.targetTenantId
    $sourceDir = Resolve-WorkflowPath $root 'output/source'
    $targetDir = Resolve-WorkflowPath $root 'output/target'
    $outputDir = Resolve-WorkflowPath $root 'output'
    if ($stage -eq 'AllReadOnly') {
        $steps = @('InventorySource','InventoryTarget')
        if ($Options.IncludeServices) { $steps += @('ServicesSource','ServicesTarget') }
        $steps += @('IdentityMap','Assess','DnsAudit')
        Write-Host "Read-only workflow: $($steps -join ' -> ')"
        foreach ($step in $steps) {
            $next = @{}
            foreach ($key in $Options.Keys) { $next[$key] = $Options[$key] }
            $next.Stage = $step
            Invoke-MigrationStage -Options $next
        }
        Write-Warning 'Discovery done. Readiness may report BLOCKED until identities are provisioned and approved. No tenant objects were changed.'
        return
    }
    switch ($stage) {
        'InventorySource' {
            $arguments = @('-TenantId',$source,'-OutputDirectory',$sourceDir)
            if ($Options.SkipIntune) { $arguments += '-SkipIntune' }
            Invoke-WorkflowHelper $Options 'Export-GraphInventory.ps1' $arguments
            Assert-InventoryComplete $Options 'source'
            break
        }
        'InventoryTarget' {
            $arguments = @('-TenantId',$target,'-OutputDirectory',$targetDir)
            if ($Options.SkipIntune) { $arguments += '-SkipIntune' }
            Invoke-WorkflowHelper $Options 'Export-GraphInventory.ps1' $arguments
            Assert-InventoryComplete $Options 'target'
            break
        }
        { $_ -in @('ServicesSource','ServicesTarget') } {
            $isSource = $stage -eq 'ServicesSource'
            $tenant = if ($isSource) { $source } else { $target }
            $dir = if ($isSource) { $sourceDir } else { $targetDir }
            $adminUrl = if ($isSource) { $Options.SourceSPOAdminUrl } else { $Options.TargetSPOAdminUrl }
            if (-not $adminUrl) { $adminUrl = if ($isSource) { $c['sourceSPOAdminUrl'] } else { $c['targetSPOAdminUrl'] } }
            if (-not $Options.SkipSharePoint -and -not $adminUrl) { throw "Missing SharePoint admin URL for $stage. Specify -SourceSPOAdminUrl/-TargetSPOAdminUrl, set config URLs, or explicitly -SkipSharePoint." }
            $arguments = @('-TenantId',$tenant,'-OutputDirectory',$dir)
            if ($adminUrl) { $arguments += @('-SPOAdminUrl',[string]$adminUrl) }
            if ($Options.SkipExchange) { $arguments += '-SkipExchange' }
            if ($Options.SkipTeams) { $arguments += '-SkipTeams' }
            if ($Options.SkipSharePoint) { $arguments += '-SkipSharePoint' }
            Invoke-WorkflowHelper $Options 'Export-ServiceInventory.ps1' $arguments
            break
        }
        'IdentityMap' {
            Assert-InventoryComplete $Options 'source'
            $mapping = Get-CurrentMapping -Options $Options
            if (Test-Path -LiteralPath $mapping) {
                $existing = @(Import-Csv -LiteralPath $mapping)
                if (@($existing | Where-Object { $_.approved -eq 'true' -or $_.targetId }).Count -gt 0) {
                    throw "Refusing to overwrite an existing approved/mapped CSV: $mapping. Back up and explicitly choose a different -MappingCsv for a new proposal."
                }
            }
            $arguments = @('-SourceUsers', (Join-Path $sourceDir 'users.json'), '-TargetStagingDomain',[string]$c.targetStagingDomain, '-OutputPath',$mapping)
            $mb = Join-Path $sourceDir 'mailboxes.json'
            if (Test-Path -LiteralPath $mb) { $arguments += @('-SourceMailboxes',$mb) }
            Invoke-WorkflowHelper $Options 'New-IdentityMap.ps1' $arguments
            Write-Warning "Approve mappings (including sourcePrimarySMTP) in $mapping before target provisioning."
            break
        }
        'Assess' {
            Assert-InventoryComplete $Options 'source'
            Assert-InventoryComplete $Options 'target'
            $mapping = Get-CurrentMapping -Options $Options -PreferTarget
            if (-not (Test-Path -LiteralPath $mapping)) { throw "Missing identity mapping: $mapping" }
            Invoke-WorkflowPython $Options 'assess.py' @('--source',$sourceDir,'--target',$targetDir,'--mapping',$mapping,'--output',(Join-Path $outputDir 'readiness.json'))
            $report = Get-Content -LiteralPath (Join-Path $outputDir 'readiness.json') -Raw | ConvertFrom-Json
            if ($report.status -eq 'BLOCKED') { Write-Warning 'Assessment BLOCKED. Resolve issues before migration; status is not GO.' }
            else { Write-Warning 'Assessment still requires service-specific manual gates and human signoff.' }
            break
        }
        'DnsAudit' {
            if (-not $c.cutoverDomain) { throw 'cutoverDomain is required in configuration.' }
            Invoke-WorkflowHelper $Options 'Test-DnsReadiness.ps1' @('-Domain',[string]$c.cutoverDomain,'-OutputPath',(Join-Path $outputDir 'dns-audit.json'))
            break
        }
        'TargetUsers' {
            $mapping = Get-CurrentMapping -Options $Options
            if (-not (Test-Path -LiteralPath $mapping)) { throw "Missing approved mapping source: $mapping" }
            $output = Resolve-WorkflowPath $root 'output/identity-map-target.csv'
            if ($mapping -eq $output) { throw 'Refusing to overwrite existing target mapping; use identity-map.csv as the TargetUsers input.' }
            $organization = if ($c['targetOrganization']) { [string]$c['targetOrganization'] } else { [string]$c.targetStagingDomain }
            $arguments = @('-TargetTenantId',$target,'-TargetOrganization',$organization,'-MappingCsv',$mapping,'-TargetStagingDomain',[string]$c.targetStagingDomain,'-OutputCsv',$output)
            if ($Options.Execute) {
                if ($Options.ApprovalPhrase -cne "CREATE-MAILUSERS:$target") { throw "Target provisioning requires -ApprovalPhrase 'CREATE-MAILUSERS:$target' and -Execute." }
                $arguments += @('-Execute','-ApprovalPhrase',$Options.ApprovalPhrase)
            }
            Invoke-WorkflowHelper $Options 'New-CloudTargetUsers.ps1' $arguments
            break
        }
        'Ctim' {
            if (-not $Options.CtimPhase) { throw 'Ctim requires -CtimPhase Bootstrap|SourceCopy|TargetAccept|TargetMap|TargetWrite|TargetReport.' }
            $phase = [string]$Options.CtimPhase
            $role = [string]$Options.TenantRole
            if ($phase -eq 'SourceCopy' -and $role -ne 'Source') { throw 'CTIM SourceCopy must run with -TenantRole Source.' }
            if ($phase -in @('TargetAccept','TargetMap','TargetWrite','TargetReport') -and $role -ne 'Target') { throw "CTIM $phase must run with -TenantRole Target." }
            $current = if ($role -eq 'Source') { $source } else { $target }
            $other = if ($role -eq 'Source') { $target } else { $source }
            $arguments = @('-Phase',$phase,'-CurrentTenantId',$current,'-OtherTenantId',$other)
            if ($Options.SourceScopeSecurityGroupId -ne [guid]::Empty) { $arguments += @('-SourceScopeSecurityGroupId',[string]$Options.SourceScopeSecurityGroupId) }
            if ($Options.RequestId -ne [guid]::Empty) { $arguments += @('-RequestId',[string]$Options.RequestId) }
            if ($Options.Execute) {
                if ($Options.ApprovalPhrase -cne "CTIM:$($current):$phase") { throw "CTIM needs -ApprovalPhrase 'CTIM:$($current):$phase' plus -Execute." }
                $arguments += @('-Execute','-ApprovalPhrase',$Options.ApprovalPhrase)
            }
            Invoke-WorkflowHelper $Options 'Invoke-Ctim.ps1' $arguments
            break
        }
        'MailboxReadiness' {
            $mapping = Get-CurrentMapping -Options $Options -PreferTarget
            $organization = if ($c['targetOrganization']) { [string]$c['targetOrganization'] } else { [string]$c.targetStagingDomain }
            Invoke-WorkflowHelper $Options 'Test-TargetMailboxReadiness.ps1' @('-Organization',$organization,'-MappingCsv',$mapping,'-OutputPath',(Join-Path $outputDir 'mailbox-readiness.json'))
            break
        }
        { $_ -in @('MigrationPreview','MigrationCreate','MigrationValidate','MigrationStatus','MigrationStart') } {
            $actions = @{ MigrationPreview='Preview'; MigrationCreate='Create'; MigrationValidate='Validate'; MigrationStatus='Status'; MigrationStart='Migrate' }
            $action = $actions[$stage]
            $arguments = @('-Action',$action,'-ConfigPath',$configPath)
            if ($action -in @('Preview','Create')) {
                if (-not $Options.CutoverUtc) { throw "$stage needs -CutoverUtc YYYY-MM-DDTHH:mm:ssZ." }
                $mapping = Get-CurrentMapping -Options $Options -PreferTarget
                if (-not (Test-Path -LiteralPath $mapping)) { throw "Mapping CSV missing: $mapping" }
                $arguments += @('-MappingCsv',$mapping,'-CutoverUtc',[string]$Options.CutoverUtc)
            }
            else {
                if (-not $Options.JobId) { throw "$stage requires -JobId." }
                $arguments += @('-JobId',[string]$Options.JobId)
            }
            if ($action -in @('Create','Validate','Migrate')) {
                if (-not $Options.Execute -or $Options.ApprovalPhrase -cne "APPROVED:$target") { throw "BLOCKED: $stage requires -Execute -ApprovalPhrase 'APPROVED:$target'." }
                $arguments += @('-Execute','-ApprovalPhrase',$Options.ApprovalPhrase)
            }
            Invoke-WorkflowHelper $Options 'Invoke-NativeOrchestrator.ps1' $arguments
            break
        }
        default { throw "Unknown workflow stage: $stage" }
    }
}

function Start-MigrationConsole {
    [CmdletBinding()]
    param([Parameter(Mandatory)][hashtable]$Options)
    $menu = [ordered]@{
        '1'='Plan'; '2'='Prerequisites'; '3'='AllReadOnly'; '4'='InventorySource';
        '5'='InventoryTarget'; '6'='ServicesSource'; '7'='ServicesTarget';
        '8'='IdentityMap'; '9'='Assess'; '10'='DnsAudit'; '11'='TargetUsers';
        '12'='Ctim'; '13'='MailboxReadiness'; '14'='MigrationPreview';
        '15'='MigrationCreate'; '16'='MigrationValidate'; '17'='MigrationStatus';
        '18'='MigrationStart'
    }
    Write-Warning 'Interactive console does not bypass licensing, compatibility, approval or manual-workload gates.'
    while ($true) {
        Write-Host "`nCloud-only M365 migration  |  config: $($Options.ConfigPath)" -ForegroundColor Cyan
        foreach ($key in $menu.Keys) { Write-Host ("{0,2}. {1}" -f $key,$menu[$key]) }
        $choice = Read-Host 'Select stage (Q to quit)'
        if ($choice -in @('Q','q','quit','exit')) { return }
        if (-not $menu.Contains($choice)) { Write-Warning 'Unknown menu option'; continue }
        $current = @{}
        foreach ($key in $Options.Keys) { $current[$key] = $Options[$key] }
        $current.Stage = $menu[$choice]
        $current.Execute = $false
        $current.ApprovalPhrase = $null
        if ($current.Stage -eq 'AllReadOnly') { $current.IncludeServices = (Read-Host 'Include Exchange, Teams & SPO inventories? Type YES') -ceq 'YES' }
        if ($current.Stage -eq 'Ctim') {
            $current.CtimPhase = Read-Host 'CTIM phase: Bootstrap/SourceCopy/TargetAccept/TargetMap/TargetWrite/TargetReport'
            $current.TenantRole = Read-Host 'Current sign-in tenant role: Source or Target'
            if ($current.TenantRole -notin @('Source','Target')) { Write-Warning 'Invalid role'; continue }
            if ($current.CtimPhase -notin @('Bootstrap','SourceCopy','TargetAccept','TargetMap','TargetWrite','TargetReport')) { Write-Warning 'Invalid phase'; continue }
            if ($current.CtimPhase -eq 'SourceCopy') { $current.SourceScopeSecurityGroupId = [guid](Read-Host 'Source scope security group GUID') }
            if ($current.CtimPhase -eq 'TargetAccept') { $current.RequestId = [guid](Read-Host 'Source copy request GUID') }
        }
        if ($current.Stage -in @('MigrationPreview','MigrationCreate')) { $current.CutoverUtc = Read-Host 'Cutover UTC ISO-8601 (e.g. 2026-12-15T02:00:00Z)' }
        if ($current.Stage -in @('MigrationValidate','MigrationStatus','MigrationStart')) { $current.JobId = Read-Host 'Migration Job ID' }
        if ($current.Stage -in @('TargetUsers','Ctim','MigrationCreate','MigrationValidate','MigrationStart')) {
            if ((Read-Host 'Execute writes? Type YES exactly; anything else is preview only') -ceq 'YES') {
                $current.Execute = $true
                $current.ApprovalPhrase = Read-Host 'Enter exact stage-and-tenant approval phrase (shown in README)'
            }
        }
        try { Invoke-MigrationStage -Options $current }
        catch { Write-Error -ErrorAction Continue "Stage $($current.Stage) STOPPED: $($_.Exception.Message)" }
    }
}
Export-ModuleMember -Function Invoke-MigrationStage,Start-MigrationConsole
