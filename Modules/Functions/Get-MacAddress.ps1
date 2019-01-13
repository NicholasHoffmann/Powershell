Function Get-MacAddress{
<#
 .Synopsis
    Retrieves the mac addresses of a computer.

 .Description
    Retrieves the mac addresses of a computer by quering WMI.

 .Parameter ComputerName
    The name of the computer, leave blank for host computer

 .Parameter Properties
    The properties to extract from WMI

 .Example
    Get-MacAddress -ComputerName 'Server01'

#>

    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $False, ValueFromPipeline = $True)]
        [Object]$ComputerName = $ENV:ComputerName,
        [Parameter(Mandatory = $False)]
        [String]$Properties = "AdapterType,MacAddress,ServiceName,NetConnectionID"
    )

    Begin{}

    Process{
        if(Test-Connection -ComputerName $ComputerName -Count 2 -Quiet){
            Try{
                $Selection = $Properties.Split(",")
                $NetworkAdapters = Gwmi -Query "Select $Properties From Win32_NetworkAdapter" -ComputerName $ComputerName | Select $Selection | Where-Object {$_.AdapterType -eq 'Ethernet 802.3'}
            }
            Catch{
                Write-Verbose "Was unable to query $ComputerName's WMI"
                Return 2
            }
        }
        Else{
            Write-Verbose "Was unable to ping $ComputerName."
            Return 1
        }
    }
    End{
        Return $NetworkAdapters
    }
}