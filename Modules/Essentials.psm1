Function  Get-CDriveSpace{
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $False, ValueFromPipeline = $True)]
        [object]$ComputerName = $ENV:ComputerName,

        [Parameter(Mandatory = $False)]
        [ValidateSet('Byte','KiloByte','MegaByte','GigaByte','TeraByte')]
        [string]$Unit = 'GigaByte'
    )
    Begin{    
        switch ($unit){
        'Byte'{$Power = 0}
        'KiloByte'{$Power = 1}
        'MegaByte'{$Power = 2}
        'GigaByte'{$Power = 3}
        'TeraByte'{$Power = 4}
        }
        $Query = "Select FreeSpace from Win32_LogicalDisk Where DeviceID like 'C:'"
    }

    Process{
        $FreeSpace = (Get-WmiObject -Query $Query -ComputerName $ComputerName | ForEach-Object {$_.FreeSpace/[math]::Pow(1024,$Power)})
    }

    End{
        Return $FreeSpace
    }
}