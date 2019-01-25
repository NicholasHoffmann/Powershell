#function that gets the capacity of the installed Physical memory

Function Get-PhysicalMemoryCapacity{
    [cmdletBinding()]
    Param(
        [Parameter(Mandatory = $False, ValueFromPipeline = $True)]
        [object]$ComputerName = $ENV:ComputerName

    )
    Begin{
        $Query = "Select Capacity from Win32_PhysicalMemory"
        $Namespace = "Root\CimV2"
    }

    Process{
        $Capacity = $Null
        if(Test-Connection -ComputerName $ComputerName -Count 2 -Quiet){
            Try{
                $Capacity = (Get-WmiObject -ComputerName $ComputerName -Query $Query -Namespace $Namespace | Measure-Object -Property Capacity -Sum).Sum
                $Capacity = $Capacity/[Math]::Pow(1024,3)
            }
            Catch{
                Write-Error -Message "Unable to Query WMI on Computer $ComputerName"
            }
        }
        Else{
            Write-Error -Message "Unable to ping Computer $ComputerName"
        }
    }

    End{
        Return $Capacity
    }
}
