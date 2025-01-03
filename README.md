# Get-MachineStatusFromSentinelOne

## Overview
This PowerShell script retrieves the quarantine status and other details of a machine from SentinelOne.

## Description
The script contains two main functions:
1. **Get-MachineIDFromS1**: Retrieves the machine ID from SentinelOne based on the machine name.
2. **Get-QuarantineStateFromS1**: Retrieves the quarantine state and other details of the machine using the machine ID.

## Parameters
- `MachineName`: The name of the machine for which the quarantine state is to be retrieved.

## Usage
```powershell
Get-QuarantineStateFromS1 -MachineName "<YourMachineNameHere>"
```

## Output Example
```
Machine status in Sentinel1:

Agent Version                    : 24.1.4.257
Computer Name                    : MyMachineName
Machine ID                       : SentinelOneMachineID
Group Name                       : SentinelOneGroupName
isActive                         : True
Last Active Date (UTC)           : 2024-12-19 15:01:39
Network Status                   : connected
Last Logged In User UPN          : myupn@domain.com
Last Logged In Username          : myusername
Last Logged In User Display Name : Full Name
```

## Notes
Replace <span style="color: red">`'YOUR_TOKEN_HERE'`</span> in the script with your actual SentinelOne token.

:information_source: Ensure you have the necessary permissions to access the SentinelOne API! :information_source:
