# Login if not already connected
if (-not (Get-MgContext)) {
    Connect-MgGraph -Scopes "Group.Read.All", "User.Read.All", "Device.Read.All", "Directory.Read.All"
}

$outputFile = "AllGroupObjects.csv"
$errorLog = "GroupExtractionErrors.txt"
$results = @()

# Clear previous logs
if (Test-Path $errorLog) { Remove-Item $errorLog }

# Fetch groups
Write-Host "`n📥 Fetching all groups..." -ForegroundColor Cyan
$groups = Get-MgGroup -All | Select-Object displayName, Id, groupTypes, mail

# Classify groups
$groupData = foreach ($group in $groups) {
    $groupType = if ($group.groupTypes -contains "Unified") { "Microsoft 365" } else { "Security" }
    $membershipType = if ($group.groupTypes -contains "DynamicMembership") { "Dynamic" } else { "Assigned" }

    [PSCustomObject]@{
        Id              = $group.Id
        DisplayName     = $group.displayName
        Mail            = $group.mail
        GroupType       = $groupType
        MembershipType  = $membershipType
    }
}

# Function to resolve object info
function Resolve-ObjectDetails {
    param (
        [string]$id,
        [string]$type
    )

    try {
        switch ($type) {
            '#microsoft.graph.user' {
                $u = Get-MgUser -UserId $id
                return @{ DisplayName = $u.DisplayName; PrincipalName = $u.UserPrincipalName }
            }
            '#microsoft.graph.device' {
                $d = Get-MgDevice -DeviceId $id
                return @{ DisplayName = $d.DisplayName; PrincipalName = $d.DeviceId }
            }
            '#microsoft.graph.group' {
                $g = Get-MgGroup -GroupId $id
                return @{ DisplayName = $g.DisplayName; PrincipalName = $g.Mail }
            }
            '#microsoft.graph.servicePrincipal' {
                $sp = Get-MgServicePrincipal -ServicePrincipalId $id
                return @{ DisplayName = $sp.DisplayName; PrincipalName = $sp.AppId }
            }
            default {
                return @{ DisplayName = ""; PrincipalName = "" }
            }
        }
    } catch {
        "`[$(Get-Date)] ❌ Error resolving object details for ID $id of type $type`n$($_.Exception.Message)`n" | Out-File -FilePath $errorLog -Append
        return @{ DisplayName = ""; PrincipalName = "" }
    }
}

# Main loop
foreach ($g in $groupData) {
    Write-Host "`n📘 Retrieving group members for: $($g.DisplayName)" -ForegroundColor Yellow

    try {
        $members = Get-MgGroupMember -GroupId $g.Id -All

        if ($members.Count -eq 0) {
            Write-Host "🚫 No members found in $($g.DisplayName)" -ForegroundColor DarkGray
        }

        foreach ($m in $members) {
            $type = $m.AdditionalProperties.'@odata.type'
            $details = Resolve-ObjectDetails -id $m.Id -type $type

            $results += [PSCustomObject]@{
                GroupId           = $g.Id
                GroupDisplayName  = $g.DisplayName
                Mail              = $g.Mail
                GroupType         = $g.GroupType
                MembershipType    = $g.MembershipType
                Role              = "Member"
                ObjectId          = $m.Id
                ObjectType        = $type -replace '#microsoft.graph.', ''
                ObjectDisplayName = $details.DisplayName
                ObjectIdentifier  = $details.PrincipalName
            }
        }
    } catch {
        "`[$(Get-Date)] ❌ Error retrieving members for group $($g.DisplayName) ($($g.Id))`n$($_.Exception.Message)`n" | Out-File -FilePath $errorLog -Append
    }

    Write-Host "📙 Retrieving group owners for: $($g.DisplayName)" -ForegroundColor Green

    try {
        $owners = Get-MgGroupOwner -GroupId $g.Id -All

        if ($owners.Count -eq 0) {
            Write-Host "🚫 No owners found in $($g.DisplayName)" -ForegroundColor DarkGray
        }

        foreach ($o in $owners) {
            $type = $o.AdditionalProperties.'@odata.type'
            $details = Resolve-ObjectDetails -id $o.Id -type $type

            $results += [PSCustomObject]@{
                GroupId           = $g.Id
                GroupDisplayName  = $g.DisplayName
                Mail              = $g.Mail
                GroupType         = $g.GroupType
                MembershipType    = $g.MembershipType
                Role              = "Owner"
                ObjectId          = $o.Id
                ObjectType        = $type -replace '#microsoft.graph.', ''
                ObjectDisplayName = $details.DisplayName
                ObjectIdentifier  = $details.PrincipalName
            }
        }
    } catch {
        "`[$(Get-Date)] ❌ Error retrieving owners for group $($g.DisplayName) ($($g.Id))`n$($_.Exception.Message)`n" | Out-File -FilePath $errorLog -Append
    }
}

# Final export
Write-Host "`n💾 Exporting results to CSV: $outputFile" -ForegroundColor Cyan
$results | Export-Csv -Path $outputFile -NoTypeInformation -Encoding UTF8

Write-Host "`n✅ Completed! Exported $($results.Count) records." -ForegroundColor Green
if (Test-Path $errorLog) {
    Write-Host "⚠️ Some errors occurred. See: $errorLog" -ForegroundColor Red
}
