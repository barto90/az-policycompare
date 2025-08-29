# Publishing AzPolicyCompare to PowerShell Gallery

This guide explains how to publish the AzPolicyCompare module to the PowerShell Gallery.

## Prerequisites

1. **PowerShell Gallery Account**: Create an account at https://www.powershellgallery.com/
2. **API Key**: Get your API key from your PowerShell Gallery profile
3. **PowerShellGet Module**: Ensure you have the latest version
4. **PowerShell 7.0+**: Module requires PowerShell 7.0 or later

```powershell
Install-Module -Name PowerShellGet -Force -AllowClobber
```

## Pre-Publication Checklist

✅ **Module Structure**
- [x] AzPolicyCompare.psd1 (manifest)
- [x] AzPolicyCompare.psm1 (module)
- [x] README.md (documentation)
- [x] LICENSE (MIT license)

✅ **Manifest Validation**
```powershell
Test-ModuleManifest -Path ".\AzPolicyCompare.psd1"
```

✅ **Module Testing**
```powershell
Import-Module ".\AzPolicyCompare.psd1" -Force
Get-Command -Module AzPolicyCompare
```

✅ **Required Fields**
- [x] Author: Bart Pasmans
- [x] Company: bartpasmans.tech
- [x] Description: Comprehensive description
- [x] Version: 1.0.0
- [x] PowerShell Version: 7.0+
- [x] Dependencies: Az.Resources
- [x] Function Export: Start-AzPolicyInitiativeComparison
- [x] Tags: Azure, Policy, Compliance, etc.
- [x] License URI
- [x] Project URI

## Publishing Steps

### 1. Set API Key
```powershell
# Set your PowerShell Gallery API key (get from https://www.powershellgallery.com/account/apikeys)
$ApiKey = "YOUR-API-KEY-HERE"
```

### 2. Final Validation
```powershell
# Test the module one more time
Import-Module ".\AzPolicyCompare.psd1" -Force -Verbose

# Verify exported function
Get-Command Start-AzPolicyInitiativeComparison

# Check manifest
Test-ModuleManifest -Path ".\AzPolicyCompare.psd1" -Verbose
```

### 3. Test Function
```powershell
# Test that the function is available and has correct help
Get-Help Start-AzPolicyInitiativeComparison -Full
```

### 4. Publish to Gallery
```powershell
# Test publication first (recommended)
Publish-Module -Path "." -NuGetApiKey $ApiKey -WhatIf -Verbose

# Actual publication
Publish-Module -Path "." -NuGetApiKey $ApiKey -Verbose
```

### 5. Verify Publication
```powershell
# Check if module is available (may take a few minutes)
Find-Module -Name AzPolicyCompare

# Install from gallery to test
Install-Module -Name AzPolicyCompare -Scope CurrentUser -Force
```

## Post-Publication

### Version Updates
For future updates:

1. Update the version in `AzPolicyCompare.psd1`
2. Update release notes
3. Test thoroughly
4. Publish new version:

```powershell
Publish-Module -Path "." -NuGetApiKey $ApiKey -Verbose
```

### Documentation Updates
- Update README.md with new features
- Update examples and use cases
- Keep changelog updated

## Gallery Requirements Met

✅ **Mandatory Requirements**
- [x] Valid PowerShell module structure
- [x] Module manifest with required metadata
- [x] Unique module name
- [x] Valid semantic version
- [x] Description (at least 10 characters)
- [x] Author information
- [x] PowerShell version compatibility (7.0+)

✅ **Best Practices**
- [x] Comprehensive README
- [x] License file (MIT)
- [x] Meaningful tags
- [x] Project URI
- [x] Release notes
- [x] Help documentation in functions
- [x] Error handling

✅ **Quality Standards**
- [x] Function uses approved verb (Start-)
- [x] Parameter validation
- [x] Error handling with try/catch
- [x] Progress indicators for long operations
- [x] Consistent naming convention

## Module Information

**Name**: AzPolicyCompare  
**Author**: Bart Pasmans  
**Company**: bartpasmans.tech  
**Version**: 1.0.0  
**PowerShell**: 7.0+  
**License**: MIT  
**Main Function**: Start-AzPolicyInitiativeComparison  

## Troubleshooting

### Common Issues

**"Module name already exists"**
- Choose a different name or contact gallery support

**"Invalid manifest"**
- Run `Test-ModuleManifest` to identify issues
- Check all required fields are present

**"PowerShell version requirement"**
- Ensure you're testing with PowerShell 7.0+
- Update local PowerShell if needed

**"API key invalid"**
- Regenerate API key from PowerShell Gallery
- Ensure no spaces or special characters

**"Upload timeout"**
- Check internet connection
- Try again later (gallery may be busy)

### Support
- PowerShell Gallery: https://www.powershellgallery.com/
- Documentation: https://docs.microsoft.com/powershell/gallery/

Ready for publication! 🚀