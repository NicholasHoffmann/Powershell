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
        $Objects | Add-Member -NotePropertyMembers $ExtraProperties
    }
    ELse{
        Write-Verbose "No Extra Properties Specified"    
    }

    return $Objects
}