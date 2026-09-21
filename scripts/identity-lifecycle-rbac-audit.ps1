<#
.SYNOPSIS
    Active Directory Identity Lifecycle Management (JML) & RBAC
    Environment: DC01, arthurlab.test (Windows Server 2025, Hyper-V)

.DESCRIPTION
    Consolidated PowerShell commands from a hands-on IAM project covering:
      1. Domain / forest / DNS validation after standing up DC01
      2. Role-based access control (RBAC) via global security groups + NTFS
      3. Joiner workflow (Sarah Johnson - Finance)
      4. Negative authorization test (Michael Davis - IT, no Finance access)
      5. Mover workflow (Sarah Johnson: Finance -> Human Resources) including
         privilege-creep detection and remediation
      6. Leaver workflow (Michael Davis: disable + segregate)

    Run interactively, section by section, on a domain controller with the
    ActiveDirectory PowerShell module available.

.NOTES
    Author: Anthony Arthur
    Full write-up with screenshots: ../README.md
#>

# ---------------------------------------------------------------------------
# 1. Domain Validation
# ---------------------------------------------------------------------------

Get-ADDomain
Get-ADForest
Get-ADDomainController
nslookup arthurlab.test

# ---------------------------------------------------------------------------
# 2. Joiner Workflow - Sarah Johnson (Finance)
# ---------------------------------------------------------------------------

# Step 9 - Confirm group membership after adding Sarah to GG-Finance-Users
Get-ADUser sjohnson -Properties MemberOf | Select-Object Name,UserPrincipalName,Enabled,MemberOf
Get-ADGroupMember "GG-Finance-Users"

# ---------------------------------------------------------------------------
# 3. Negative Authorization Test - Michael Davis (IT)
# ---------------------------------------------------------------------------

# Step 13 - Confirm Michael has no Finance group membership / access
Get-ADPrincipalGroupMembership mdavis | Select-Object Name
Get-ADGroupMember "GG-Finance-Users"

# ---------------------------------------------------------------------------
# 4. Mover Workflow - Sarah Johnson (Finance -> Human Resources)
# ---------------------------------------------------------------------------

# Step 15 - Detect privilege creep after the department transfer
Get-ADPrincipalGroupMembership sjohnson | Select-Object Name

# Step 16 - Remediate entitlements: remove stale Finance access, grant HR access
Remove-ADGroupMember -Identity "GG-Finance-Users" -Members sjohnson
Add-ADGroupMember -Identity "GG-HR-Users" -Members sjohnson
Get-ADPrincipalGroupMembership sjohnson | Select-Object Name

# ---------------------------------------------------------------------------
# 5. Leaver Workflow - Michael Davis (Offboarding)
# ---------------------------------------------------------------------------

# Step 19 - Establish offboarding baseline
Get-ADUser mdavis -Properties Enabled,Department,Title,MemberOf | Select-Object `
    Name,Enabled,Department,Title,MemberOf
Get-ADPrincipalGroupMembership mdavis | Select-Object Name

# Step 20 - Disable the account
Disable-ADAccount -Identity mdavis
Get-ADUser mdavis -Properties Enabled | Select-Object Name,SamAccountName,Enabled

# Step 22 - Final offboarding validation (post move to Disabled Users OU)
Get-ADPrincipalGroupMembership mdavis | Select-Object Name
Get-ADUser mdavis -Properties Enabled,Department,Title,LastLogonDate | Select-Object `
    Name,Enabled,Department,Title,LastLogonDate,DistinguishedName

# ---------------------------------------------------------------------------
# 6. Key Commands Reference
# ---------------------------------------------------------------------------

# Domain validation:      Get-ADDomain; Get-ADForest; Get-ADDomainController; nslookup arthurlab.test
# Identity review:        Get-ADUser -Properties ...
# Group review:           Get-ADPrincipalGroupMembership ; Get-ADGroupMember
# Entitlement remediation:Remove-ADGroupMember; Add-ADGroupMember
# NTFS review:            (Get-Acl "C:\FinanceData").Access | Format-Table IdentityReference,FileSystemRights,AccessControlType
# Offboarding:            Disable-ADAccount -Identity mdavis
