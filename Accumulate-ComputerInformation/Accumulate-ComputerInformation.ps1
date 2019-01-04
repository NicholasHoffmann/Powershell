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


Function Get-MonitorInformation{
    [cmdletBinding()]
    Param(
        [Parameter(Mandatory = $True)]
        [string]$ComputerName
    )

    $Command
    $Monitors = 
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