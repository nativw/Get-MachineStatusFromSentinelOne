<#
.SYNOPSIS
    This script retrieves the quarantine state of a machine from SentinelOne.

.DESCRIPTION
    The script contains two functions:
    1. Get-MachineIDFromS1: Retrieves the machine ID from SentinelOne based on the machine name.
    2. Get-QuarantineStateFromS1: Retrieves the quarantine state and other details of the machine using the machine ID.

.PARAMETER MachineName
    The name of the machine for which the quarantine state is to be retrieved.

.EXAMPLE
    Get-QuarantineStateFromS1 -MachineName "MachineName"

.NOTES
    Author: Nativ Weiss
    Date: 19-12-2024
#>

$S1Token = 'YOUR_TOKEN_HERE'

function Get-MachineIDFromS1 {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $MachineName
    )

    $Token = $S1Token
    $Headers = @{
        Authorization = "Bearer $Token"
    }

    $URI = "https://usea1-kla.sentinelone.net/web/api/v2.1/agents?computerName__like=$MachineName"
    
    try {
        $response = Invoke-WebRequest -Uri $URI -Headers $Headers -Method Get -ErrorAction Stop
    }
    catch {
        Write-Host "There was an error invoking the API request."
        $_.exception
        return
    }

    $StatusCode = $response.StatusCode

    if ($StatusCode -ne 200) {
        throw "Error occoured: $StatusCode"
        return
    }

    $jsonContent = $response.Content | ConvertFrom-Json

    # Extract the "Data" property
    $data = $jsonContent.data

    if ($null -eq $data.ID) {
        return ("Unable to find the machine `"$MachineName`" in Sentinel1. Please check if you spelled correctly.")
    }

    # Sort the data by lastActiveDate and select the ID property
    $sortedData = $data | Sort-Object lastActiveDate -Descending
    $machineId = $sortedData[0].ID
    
    return $machineId
}
function Get-QuarantineStateFromS1 {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $MachineName
    )

    $MachineID = Get-MachineIDFromS1 -MachineName $MachineName

    if ($MachineID -like "Unable*") {
        Write-Host $MachineID
        return
    }
    
    $Token = $S1Token
    $Headers = @{
        Authorization = "Bearer $Token"
    }

    $machineObject = [PSCustomObject]@{
        "Agent Version"                    = $null
        "Computer Name"                    = $MachineName
        "Machine ID"                       = $null
        "Group Name"                       = $null
        isActive                           = $null
        "Last Active Date (UTC)"           = $null
        "Network Status"                   = $null
        "Last Logged In User UPN"          = $null
        "Last Logged In Username"          = $null
        "Last Logged In User Display Name" = $null
    }

    $URI = "https://usea1-kla.sentinelone.net/web/api/v2.1/agents?ids=$MachineID"

    try {
        $response = Invoke-WebRequest -Uri $URI -Headers $Headers -Method Get -ErrorAction Stop
    }
    catch {
        Write-Host "There was an error invoking the API request."
        $_.exception
        return
    }

    $StatusCode = $response.StatusCode
    
    if ($StatusCode -ne 200) {
        throw "Error occoured: $StatusCode"
        return
    }

    $jsonContent = $response.Content | ConvertFrom-Json

    # Extract the "Data" property
    $data = $jsonContent.data[0]
  
    # Format the time stamp
    $timestamp = $data.lastActiveDate
    $formattedTimestamp = [datetime]::Parse($timestamp).ToString("yyyy-MM-dd HH:mm:ss")

    # Format the user display name
    $userDN = $data.ActiveDirectory.lastUserDistinguishedName
    $userDN -match 'CN=([^,]+)' | Out-Null
    $userDisplayName = $Matches[1]

    
    $machineObject."Agent Version" = $data.AgentVersion
    $machineObject."Machine ID" = $data.id
    $machineObject."Group Name" = $data.groupName
    $machineObject.isActive = $data.isActive
    $machineObject."Last Active Date (UTC)" = $formattedTimestamp
    $machineObject."Network Status" = $data.networkStatus
    $machineObject."Last Logged In User UPN" = $data.ActiveDirectory.userPrincipalName
    $machineObject."Last Logged In Username" = $data.lastLoggedInUserName
    $machineObject."Last Logged In User Display Name" = $userDisplayName

    # Convert the machine object to string
    $machineObjectString = $machineObject | Out-String

    # Create the return message
    $machineStatus = "Machine status in Sentinel1:`n$machineObjectString"
    $machineStatus = $machineStatus.Trim()

    return $machineStatus
}
