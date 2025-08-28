<#
.SYNOPSIS
    Azure Policy Initiative Comparison Tool v1.0

.DESCRIPTION
    Compares two Azure Policy Initiatives and identifies overlapping policies, 
    missing policies, and provides detailed analysis for compliance mapping.

.PARAMETER OutputHtml
    Optional path to export the comparison results as HTML

.EXAMPLE
    .\PolicyCompare.ps1
    Interactive mode - prompts for initiative selection

.EXAMPLE
    .\PolicyCompare.ps1 -OutputHtml "comparison-report.html"
    Interactive mode with HTML export

.NOTES
    Version: 1.0
    Requires: Az.Resources PowerShell module
#>

#Requires -Modules Az.Resources

param(
    [Parameter(Mandatory = $false)]
    [string]$OutputHtml
)

function Test-RequiredModules {
    Write-Host "Checking required modules..." -ForegroundColor Cyan
    $requiredModules = @("Az.Resources")
    foreach ($module in $requiredModules) {
        $moduleInfo = Get-Module -Name $module -ListAvailable
        if ($moduleInfo) {
            Write-Host "✓ $module module found" -ForegroundColor Green
        } else {
            Write-Error "$module module is not installed. Install with: Install-Module $module"
            exit 1
        }
    }
}

function Connect-ToAzure {
    Write-Host "Connecting to Azure..." -ForegroundColor Cyan
    try {
        $context = Get-AzContext
        if (-not $context) {
            Write-Host "No Azure context found. Please sign in..." -ForegroundColor Yellow
            Connect-AzAccount
            $context = Get-AzContext
        }
        Write-Host "✓ Connected to Azure as: $($context.Account.Id)" -ForegroundColor Green
        Write-Host "✓ Current subscription: $($context.Subscription.Name)" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to connect to Azure: $($_.Exception.Message)"
        exit 1
    }
}

function Get-AllInitiatives {
    Write-Host "Retrieving all policy initiatives..." -ForegroundColor Cyan
    try {
        $initiatives = Get-AzPolicySetDefinition
        Write-Host "Found $($initiatives.Count) policy initiatives" -ForegroundColor Green

        $sortedInitiatives = $initiatives | Sort-Object { 
            if ($_.Properties.DisplayName) { $_.Properties.DisplayName } 
            elseif ($_.DisplayName) { $_.DisplayName } 
            else { $_.Name } 
        }
        $numberedInitiatives = @()
        for ($i = 0; $i -lt $sortedInitiatives.Count; $i++) {
            $initiative = $sortedInitiatives[$i]
            $displayName = if ($initiative.Properties.DisplayName) { $initiative.Properties.DisplayName } elseif ($initiative.DisplayName) { $initiative.DisplayName } else { "Unknown Initiative" }
            $policyType = if ($initiative.Properties.PolicyType) { $initiative.Properties.PolicyType } elseif ($initiative.PolicyType) { $initiative.PolicyType } else { "Unknown" }
            $policyCount = if ($initiative.Properties.PolicyDefinitions) { $initiative.Properties.PolicyDefinitions.Count } 
                          elseif ($initiative.PolicyDefinitions) { $initiative.PolicyDefinitions.Count } 
                          elseif ($initiative.PolicyDefinition) { $initiative.PolicyDefinition.Count }
                          else { 0 }
            
            $numberedInitiatives += [PSCustomObject]@{
                Number = $i + 1
                Name = $displayName
                Type = if ($policyType -eq "BuiltIn") { "Built-in" } else { "Custom" }
                Policies = $policyCount
                OriginalName = if ($policyType -eq "BuiltIn") { $initiative.Name } else { $initiative.Id }
            }
        }
        return $numberedInitiatives
    }
    catch {
        Write-Error "Failed to retrieve initiatives: $($_.Exception.Message)"
        exit 1
    }
}

function Select-Initiative {
    param([array]$Initiatives, [string]$Purpose)
    Write-Host "`nAvailable Policy Initiatives:" -ForegroundColor Cyan
    Write-Host "=============================" -ForegroundColor Cyan
    $Initiatives | Format-Table -AutoSize | Out-Host
    Write-Host "`n"
    do {
        $selection = Read-Host "$Purpose Enter the number (1-$($Initiatives.Count))"
        if ([string]::IsNullOrWhiteSpace($selection)) {
            Write-Host "Error: Please enter a valid number. Empty values are not accepted." -ForegroundColor Red
            continue
        }
        try {
            $selectedNumber = [int]$selection
            if ($selectedNumber -ge 1 -and $selectedNumber -le $Initiatives.Count) {
                $selectedInitiative = $Initiatives[$selectedNumber - 1]
                Write-Host "`nYou selected: $($selectedInitiative.Name)" -ForegroundColor Green
                return $selectedInitiative
            } else {
                Write-Host "Error: Please enter a number between 1 and $($Initiatives.Count)" -ForegroundColor Red
            }
        }
        catch {
            Write-Host "Error: Please enter a valid number." -ForegroundColor Red
        }
    } while ($true)
}

function Get-InitiativePolicies {
    param([string]$InitiativeId, [string]$InitiativeName)
    try {
        Write-Progress -Activity "Policy Analysis" -Status "Retrieving policies from $InitiativeName" -PercentComplete 0
        $initiative = $null
        
        if ($InitiativeId.StartsWith("/")) {
            $initiative = Get-AzPolicySetDefinition -Id $InitiativeId -ErrorAction SilentlyContinue
        }
        
        if (-not $initiative) {
            $initiative = Get-AzPolicySetDefinition -Name $InitiativeId -ErrorAction SilentlyContinue
        }
        
        if (-not $initiative) {
            $allInitiatives = Get-AzPolicySetDefinition
            $initiative = $allInitiatives | Where-Object { $_.Name -eq $InitiativeId -or $_.Id -eq $InitiativeId }
        }
        if (-not $initiative) {
            Write-Error "Could not find initiative with ID: $InitiativeId"
            return @()
        }
        $policies = @()
        $policyDefs = if ($initiative.Properties.PolicyDefinitions) { $initiative.Properties.PolicyDefinitions } 
                      elseif ($initiative.PolicyDefinitions) { $initiative.PolicyDefinitions } 
                      elseif ($initiative.PolicyDefinition) { $initiative.PolicyDefinition }
                      else { @() }
        
        $totalPolicies = $policyDefs.Count
        $currentPolicy = 0
        foreach ($policyRef in $policyDefs) {
            $currentPolicy++
            $percentComplete = ($currentPolicy / $totalPolicies) * 100
            Write-Progress -Activity "Policy Analysis" -Status "Processing policy $currentPolicy of $totalPolicies" -PercentComplete $percentComplete
            $policyDef = Get-AzPolicyDefinition -Id $policyRef.PolicyDefinitionId -ErrorAction SilentlyContinue
            if ($policyDef) {
                $policyName = if ($policyDef.Properties.DisplayName) { $policyDef.Properties.DisplayName } elseif ($policyDef.DisplayName) { $policyDef.DisplayName } else { "Unknown Policy" }
                $policyCategory = if ($policyDef.Properties.Metadata.category) { $policyDef.Properties.Metadata.category } elseif ($policyDef.Metadata.category) { $policyDef.Metadata.category } else { "Unknown" }
                
                $policies += [PSCustomObject]@{
                    PolicyId = $policyRef.PolicyDefinitionId
                    PolicyName = $policyName
                    Category = $policyCategory
                }
            }
        }
        Write-Progress -Activity "Policy Analysis" -Completed
        return $policies
    }
    catch {
        Write-Error "Failed to get policies for initiative $InitiativeId : $($_.Exception.Message)"
        return @()
    }
}

function Compare-Initiatives {
    param([object]$SourceInitiative, [object]$CompareInitiative)
    Write-Host "`nAnalyzing policy overlap..." -ForegroundColor Cyan
    $sourcePolicies = Get-InitiativePolicies -InitiativeId $SourceInitiative.OriginalName -InitiativeName $SourceInitiative.Name
    $comparePolicies = Get-InitiativePolicies -InitiativeId $CompareInitiative.OriginalName -InitiativeName $CompareInitiative.Name

    Write-Progress -Activity "Policy Comparison" -Status "Finding overlaps and differences" -PercentComplete 50
    $overlap = @()
    $missingInCompare = @()
    $missingInSource = @()
    foreach ($sourcePolicy in $sourcePolicies) {
        $foundInCompare = $comparePolicies | Where-Object { $_.PolicyId -eq $sourcePolicy.PolicyId }
        if ($foundInCompare) {
            $overlap += $sourcePolicy
        } else {
            $missingInCompare += $sourcePolicy
        }
    }
    foreach ($comparePolicy in $comparePolicies) {
        $foundInSource = $sourcePolicies | Where-Object { $_.PolicyId -eq $comparePolicy.PolicyId }
        if (-not $foundInSource) {
            $missingInSource += $comparePolicy
        }
    }
    Write-Progress -Activity "Policy Comparison" -Completed
    return [PSCustomObject]@{
        OverlapCount = $overlap.Count
        OverlapPolicies = $overlap
        MissingInCompareCount = $missingInCompare.Count
        MissingInComparePolicies = $missingInCompare
        MissingInSourceCount = $missingInSource.Count
        MissingInSourcePolicies = $missingInSource
        SourceTotal = $sourcePolicies.Count
        CompareTotal = $comparePolicies.Count
    }
}

function Export-ToHtml {
    param([object]$SourceInitiative, [object]$CompareInitiative, [object]$Comparison, [string]$FilePath)
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Azure Policy Initiative Comparison</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #0078d4; color: white; padding: 20px; border-radius: 5px; }
        .section { margin: 20px 0; padding: 15px; border: 1px solid #ddd; border-radius: 5px; }
        .overlap { background-color: #d4edda; }
        .missing { background-color: #f8d7da; }
        .extra { background-color: #e2e3f1; }
        .policy-list { margin: 10px 0; }
        .policy-item { margin: 5px 0; padding: 5px; background-color: #f8f9fa; border-left: 3px solid #007bff; }
        table { width: 100%; border-collapse: collapse; margin: 10px 0; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Azure Policy Initiative Comparison Report</h1>
        <p>Generated on: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
    </div>

    <div class="section">
        <h2>Initiative Details</h2>
        <table>
            <tr><th>Aspect</th><th>Source Initiative</th><th>Compare Initiative</th></tr>
            <tr><td>Name</td><td>$($SourceInitiative.Name)</td><td>$($CompareInitiative.Name)</td></tr>
            <tr><td>Type</td><td>$($SourceInitiative.Type)</td><td>$($CompareInitiative.Type)</td></tr>
            <tr><td>Total Policies</td><td>$($Comparison.SourceTotal)</td><td>$($Comparison.CompareTotal)</td></tr>
        </table>
    </div>

    <div class="section overlap">
        <h2>Policy Overlap ($($Comparison.OverlapCount) policies)</h2>
        <p>These policies exist in both initiatives:</p>
        <div class="policy-list">
"@
    foreach ($policy in $Comparison.OverlapPolicies) {
        $html += "<div class='policy-item'>$($policy.PolicyName)</div>"
    }
    
    $html += @"
        </div>
    </div>

    <div class="section missing">
        <h2>Policies Missing in Compare Initiative ($($Comparison.MissingInCompareCount) policies)</h2>
        <p>These policies from the source initiative are not found in the compare initiative:</p>
        <div class="policy-list">
"@
    foreach ($policy in $Comparison.MissingInComparePolicies) {
        $html += "<div class='policy-item'>$($policy.PolicyName)</div>"
    }
    
    $html += @"
        </div>
    </div>

    <div class="section extra">
        <h2>Extra Policies in Compare Initiative ($($Comparison.MissingInSourceCount) policies)</h2>
        <p>These policies are in the compare initiative but not in the source initiative:</p>
        <div class="policy-list">
"@
    foreach ($policy in $Comparison.MissingInSourcePolicies) {
        $html += "<div class='policy-item'>$($policy.PolicyName)</div>"
    }
    
    $html += @"
        </div>
    </div>
</body>
</html>
"@
    
    $html | Out-File -FilePath $FilePath -Encoding UTF8
    Write-Host "HTML report exported to: $FilePath" -ForegroundColor Green
}
try {
    Write-Host "Azure Policy Initiative Comparison Tool v1.0" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
    Test-RequiredModules
    Connect-ToAzure
    $initiatives = Get-AllInitiatives
    Write-Host "`nSTEP 1: Select the SOURCE initiative" -ForegroundColor Yellow
    $sourceInitiative = Select-Initiative -Initiatives $initiatives -Purpose "Which initiative do you want to use as SOURCE?"
    Write-Host "`nSTEP 2: Select the initiative to COMPARE with" -ForegroundColor Yellow
    $compareInitiative = Select-Initiative -Initiatives $initiatives -Purpose "Which initiative do you want to COMPARE with the source?"
    $comparison = Compare-Initiatives -SourceInitiative $sourceInitiative -CompareInitiative $compareInitiative
    Write-Host "`nCOMPARISON SUMMARY" -ForegroundColor Green
    Write-Host "==================" -ForegroundColor Green
    if ($sourceInitiative.Name -eq $compareInitiative.Name) {
        Write-Host "`nWarning: You selected the same initiative for both source and comparison." -ForegroundColor Yellow
    }
    Write-Host "`n1. SOURCE Initiative:" -ForegroundColor Cyan
    Write-Host "   Name: $($sourceInitiative.Name)" -ForegroundColor White
    Write-Host "   Type: $($sourceInitiative.Type)" -ForegroundColor White
    Write-Host "   Number of policies: $($comparison.SourceTotal)" -ForegroundColor White
    Write-Host "`n2. COMPARE Initiative:" -ForegroundColor Cyan
    Write-Host "   Name: $($compareInitiative.Name)" -ForegroundColor White
    Write-Host "   Type: $($compareInitiative.Type)" -ForegroundColor White
    Write-Host "   Number of policies: $($comparison.CompareTotal)" -ForegroundColor White
    Write-Host "`n3. POLICY ANALYSIS:" -ForegroundColor Yellow
    Write-Host "   Overlapping policies: $($comparison.OverlapCount)" -ForegroundColor Green
    Write-Host "   Policies missing in '$($compareInitiative.Name)': $($comparison.MissingInCompareCount)" -ForegroundColor Red
    Write-Host "   Extra policies in '$($compareInitiative.Name)': $($comparison.MissingInSourceCount)" -ForegroundColor Magenta
    if ($comparison.MissingInCompareCount -gt 0) {
        Write-Host "`n   Policies from SOURCE missing in COMPARE initiative:" -ForegroundColor Red
        foreach ($missingPolicy in $comparison.MissingInComparePolicies) {
            Write-Host "   - $($missingPolicy.PolicyName)" -ForegroundColor White
        }
    }
    if ($comparison.MissingInSourceCount -gt 0) {
        Write-Host "`n   Extra policies in COMPARE initiative (not in SOURCE):" -ForegroundColor Magenta
        foreach ($extraPolicy in $comparison.MissingInSourcePolicies) {
            Write-Host "   + $($extraPolicy.PolicyName)" -ForegroundColor White
        }
    }
    if ($OutputHtml) {
        Export-ToHtml -SourceInitiative $sourceInitiative -CompareInitiative $compareInitiative -Comparison $comparison -FilePath $OutputHtml
    }
    Write-Host "`nScript completed successfully!" -ForegroundColor Green
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    exit 1
}
