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

Function Import-SnowCSV{

    #this is a function that simplifies the import of Snow CSV's. 
    #it may also add extra properties to the result so we can add more information easily this is specfied as a hashtable
    #this can really be used for any type of CSV but the Delimeter is Set for snow automatically


    [cmdletBinding()]
    Param(
        [Parameter(Mandatory = $True)]
        [string]$Path,
        

        [Parameter(Mandatory = $False)]
        [HashTable]$ExtraProperties,
        [string]$Delimeter = ";"
    )

    #this imports the standard Snow CSV
    Write-Verbose "Imported CSV $Path"
    $Objects = Import-Csv -Delimiter $Delimeter -Path $Path 

    #This adds any extra properties specified by the user. It will add them all as zeros
    

    if($ExtraProperties){
        Write-Verbose "Extra Properties $ExtraProperties Specified"
        $Objects | Add-Member -NotePropertyMembers $ExtraProperties -Force
    }
    ELse{
        Write-Verbose "No Extra Properties Specified"    
    }

    return $Objects
}