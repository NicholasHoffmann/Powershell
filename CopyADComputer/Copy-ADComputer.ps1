<#
This function will copy all the settings of an existing active directory computer and set them to a new one.
Such as
- The ou it should be in
- The description it should have
- The groups it should be apart of


#>

# input values will appear as so
# -SourceComputer is the Computer you want to Copy
# -Destination Computer is the Computer you want to push the settings to
# -IncludedGroups is the Groups you will allow the PC to be apart of
# -SwitchGroups is an object array of certain groups that will be using a different e.g. presto_Version_9 will switch to Presto_Version_10
# -KeepCurrentOU if this switch statement is turned on, the Computers OU will not be changed to the current PC

$IncludedGroups = Get-Content -Path (join-path -Path $PSScriptRoot -ChildPath IncludedGroups.txt)
$SwitchGroupsUnfiltered = Get-Content -Path (join-path -Path $PSScriptRoot -ChildPath swapGroups.txt)
$SwitchGroups = @()
Foreach($group in $SwitchGroupsUnfiltered){
    $SwitchGroups += new-object -TypeName PSObject -Property @{
        name = $group.split("`t")[0]
        ExchangedName = $group.split("`t")[1]
    }
}


$Command = {

    Copy-ADComputer -SourceComputer HR65MN2 -DestinationComputer GC006H2 -IncludedGroups $IncludedGroups -SwitchGroups $SwitchGroups -KeepCurrentOU -KeepCurrentDescription -AddLaptopGroups

}

function Copy-ADComputer{


    [cmdletbinding()]
    param(
        [parameter(Mandatory = $True)]
        [object]$SourceComputer,

        [parameter(Mandatory = $True)]
        [object]$DestinationComputer,

        [parameter(Mandatory = $True)]
        [object[]]$IncludedGroups,

        [parameter(Mandatory = $false)]
        [object[]]$switchGroups,

        [switch]$KeepCurrentOU,
        [switch]$KeepCurrentDescription,
        [switch]$AddLaptopGroups
    )
    $SourceComputer = $SourceComputer.ToUpper()
    $DestinationComputer = $DestinationComputer.ToUpper()

    #check if the source computer currently exists
    try{$SourceADComputer = Get-ADComputer $SourceComputer -Properties * -ErrorAction stop}
    catch{
        Write-Warning "Source computer does not exist."
        Start-Sleep 1
        return
    }

    #check if the destination computer currently exists, since there is currently a big change to the OU structure, figuring out where to place one if it does not exist is not feasible
    try{$DestinationADComputer = Get-ADComputer $DestinationComputer -Properties * -ErrorAction stop}
    Catch{  
        write-Warning "Destination computer does not exist"
        Start-Sleep 1
        return 
    }


    $SourceMembers = $SourceADComputer.memberOf
    $SourceDistinguishedName = $SourceADComputer.DistinguishedName
    $SourceOU = $SourceADComputer.DistinguishedName.TrimStart("CN=$SourceComputer,")
    $SourceDescription = $SourceADComputer.Description
    
    $DestinationOU = $DestinationADComputer.DistinguishedName.TrimStart("CN=$DestinationComputer,")

    $FilteredMembers = @()
    $Swapped = @()
    foreach($member in $SourceMembers){
        $found = $False
        $switchGroups | ? {$_.name -eq $member.split(",")[0].Replace("CN=","")} | % {
            $Group = (get-adgroup $_.ExchangedName).DistinguishedName
            $FilteredMembers += $Group
            $swapped += $_ 
            $found = $True
        }
        if(!$found){
            $FilteredMembers += $member
        }
    }

    #go through the members and find the ones to exclude
    
    $FilteredMembers2 = @()
    $excluded = @()
    foreach($member in $FilteredMembers){
        if($IncludedGroups -contains ($member.split(",")[0].Replace("CN=",""))){
            $FilteredMembers2 += $member
        }
        else{
            $excluded += $member
        }
    }

    #add the special groups that laptops get

    if($AddLaptopGroups){
        $FilteredMembers2 += "CN=ROLE_MobileManager_LockedDownLaptop,OU=Mobile Manager Laptops,OU=Resource_Access,OU=Groups,DC=abcp,DC=ab,DC=bluecross,DC=ca"
        $FilteredMembers2 += "CN=ACL_Cisco_Wireless_WCSC_Devices,OU=Wireless,OU=Network,OU=Resource_Access,OU=Groups,DC=abcp,DC=ab,DC=bluecross,DC=ca"
    }

    #Remove any duplicates
    $allGroups = @()
    foreach($group in $FilteredMembers2){
        if(!($allGroups -contains $group)){
            $allGroups += $group
        }
    }

    #we now have all the necessary information to effectively add all the groups that are required
    #let us give the user a breif breakdown of what is going to happen before going ahead and doing it

    if(!(Test-Path C:\temp\ADLogs)){
        New-Item -ItemType Directory C:\Temp\ADlogs
    }
    
    $date = get-date -Format ss-mm-hh-dd-MM-yyyy
    $logfile = "C:\temp\ADLogs\$date`_$SourceComputer`_$DestinationComputer.log"
    
    #header
    Out-File -FilePath $logfile -Append -InputObject $logfile
    
    #original Members
    Out-File -FilePath $logfile -Append -InputObject "original Members"
    Out-File -FilePath $logfile -Append -InputObject $SourceMembers

    Out-File -FilePath $logfile -Append -InputObject "`nSwapped Members"
    Out-File -FilePath $logfile -Append -InputObject $swapped

    Out-File -FilePath $logfile -Append -InputObject "`nExcluded Members"
    Out-File -FilePath $logfile -Append -InputObject $excluded
    
    Out-File -FilePath $logfile -Append -InputObject "`nFilter Members"
    Out-File -FilePath $logfile -Append -InputObject $AllGroups

    if(!$KeepCurrentOU){
        Out-file -FilePath $logfile -Append -InputObject ("Current OU = $DestinationOU")
        Out-file -FilePath $logfile -Append -InputObject ("Destination OU = $SourceOU")
    }
    else{
        Out-file -FilePath $logfile -Append -InputObject ("Ou will not change")
        Out-file -FilePath $logfile -Append -InputObject $DestinationADComputer.DistinguishedName
    }
    Start-Process $logfile
    $str = Read-Host "Please review the following changes before accepting [Y]"

    if($str -eq "y"){
        if(!$KeepCurrentOU){
            Get-ADComputer $DestinationComputer | Move-ADObject -TargetPath $SourceOU
        }
        if(!$KeepCurrentDescription){
            Set-ADComputer $DestinationComputer -Description "$SourceDescription"
        }

        foreach($member in $AllGroups){
            Add-ADGroupMember $member -Members "$DestinationComputer$"
        }
        write-host "Changes have been made succesfully."
        return 0
    }
    Else{
        Write-Warning "Adding of group members has been canceled."
        return 1
    }
    
    #property CN for Computer name
    #property DistinguishedName for full name with OUs
}

& $Command

