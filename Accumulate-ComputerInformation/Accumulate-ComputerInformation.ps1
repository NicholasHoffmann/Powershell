<#
This script will gather information on computers.
Information sources can be WMI, CMD, and possibly other inventory software


Some information will be gathered from internal websites through web scraping techniques like Invoke-WebRequest



Alot of this is going to be used in the certify-inventory script.
I figured I would rather have a master data collection script to get all my data so it can be used in multiple places without having to repurpose other code.
Certify-inventory can just read the data and apply all the rules


Here is some the information I want to collect.

Basic informmation
The ComputerName
The Mac Addresses on a PC
THe IP Address on the PC
The Operating System

Active Directory
The Computers Description
The Computers MemberOf List
The Computers Distinguised Name

WMI
The Monitors attached to a PC

Logs
Logged on events

Snow
Location
Assigned User ID
Assigned User Name
Assigned Department



#>

#Type Dynamic
Function Get-MonitorInformation{
    [cmdletBinding()]
    Param(
        [Parameter(Mandatory = $True)]
        [string]$ComputerName
    )

    $Command  = {
        $WMIMonitor = GWMI -Namespace Root\WMI -Class WMIMonitorID
        $MonitorInformation = @()
        $Count = 1
        Foreach($Instance in $WMIMonitor){
            $Object = New-object -TypeName PSobject -Property @{
                ManufacturerName = ''
                ProductCodeID = ''
                SerialNumberID = ''
                UserFriendlyName = ''
                WeekOfManufacture = ''
                YearOfManufacture = ''
                Count = 0
                ComputerName = $ComputerName
            }
            $Instance.ManufacturerName | %{$Object.ManufacturerName += [char]$_}
            $Instance.ProductCodeID | %{$Object.ProductCodeID += [char]$_}
            $Instance.SerialNumberID | %{$Object.SerialNumberID += [char]$_}
            $Instance.UserFriendlyName | %{$Object.UserFriendlyName += [char]$_}
            $Object.WeekOfManufacture = $Instance.WeekOfManufacture
            $Object.YearOfManufacture = $Instance.YearOfManufacture
            $Object.Count = $Count
            $Count++

            $MonitorInformation += $Object

        }

        return $MonitorInformation
    }

    return Invoke-Command -ComputerName $ComputerName -ScriptBlock $Command
}

#Type Static
Function Get-MacAddresses{
    [cmdletBinding()]
    Param(
        [Parameter(Mandatory = $True)]
        $ComputerName
    )

    $NetworkAdapter = Gwmi -Class Win32_NetworkAdapter | Where {$_.Speed -ne $null}
    
}

<#

192.168.1.64
192.168.1.65
192.168.1.66
192.168.1.67
192.168.1.68
192.168.1.69
192.168.1.71

#>