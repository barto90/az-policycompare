@{
    RootModule = 'AzPolicyCompare.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'c0e8112b-0882-4d02-b8f5-43c730e2fdd0'
    Author = 'Bart Pasmans'
    CompanyName = 'bartpasmans.tech'
    Copyright = '(c) 2025 Bart Pasmans. All rights reserved.'
    Description = 'PowerShell module for comparing Azure Policy Initiatives to identify overlapping policies, missing policies, and provide detailed compliance mapping analysis.'
    PowerShellVersion = '7.0'
    RequiredModules = @('Az.Resources')
    FunctionsToExport = @('Start-AzPolicyInitiativeComparison')
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('Azure', 'Policy', 'Compliance', 'Governance', 'Security', 'Initiative', 'Comparison')
            LicenseUri = 'https://github.com/bartpasmans/AzPolicyCompare/blob/main/LICENSE'
            ProjectUri = 'https://github.com/bartpasmans/AzPolicyCompare'
            IconUri = ''
            ReleaseNotes = 'Initial release of Azure Policy Initiative Comparison module.

Features:
- Compare two Azure Policy Initiatives
- Identify overlapping policies between initiatives
- Find policies missing in target initiatives
- Export detailed comparison reports to HTML
- Support for both built-in and custom policy initiatives
- Interactive initiative selection interface'
            Prerelease = ''
            RequireLicenseAcceptance = $false
            ExternalModuleDependencies = @('Az.Resources')
        }
    }
}
