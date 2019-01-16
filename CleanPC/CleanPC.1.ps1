 <#**************************************************************************************************
' FILENAME:			Operational - Workstation Cleanup.ps1
' DESCRIPTION:		Complete script for workstation cleanup.
' REFERENCE:	
' Copyright 2018, Nicholas Hoffmann, All rights reserved.
'
'
#>

<#
' VERSION			0.56Alpha
' DATE:				July 16th, 2018
' AUTHOR:			Nicholas Hoffmann
' COMMENTS:			
'
'	-Test path in the registry deleting function was wrong, now fixed
'	-scan folder size function has been changed to stop a few errors that were popping up.

Version 2
'#>




<#*************************************************************************************************
#					Settings
#************************************************************************************************#>

# Variable that halts the start of the cleaning process.
$AskBeforeStarting = $true
<#
' wildcards
' %PC = computer name
' %U  = Username
' %SID = SID for a user (Registryonly)
#>

# Declare folders to clean here, three properties must be filled out, path, what to include, and how many days ago the file was modified
$DeleteFolders = @()
$DeleteFolders += New-Object psobject -Property @{ path = "\\%PC\C$\users\%U\AppData\local\temp"; include = "*"; Daylimit = 0}
$DeleteFolders += New-Object psobject -Property @{ path = "\\%PC\C$\users\%U\AppData\local\Microsoft\Windows\Temporary Internet Files"; include = "*"; Daylimit = 0}
$DeleteFolders += New-Object psobject -Property @{ path = "\\%PC\C$\users\%U\AppData\Roaming\syntevo\SmartCVS\7.1\metacache\r0"; include = "*"; Daylimit = -180}
$DeleteFolders += New-Object psobject -Property @{ path = "\\%PC\C$\users\%U\AppData\Local\Google\Chrome";include = "*.tmp*"; Daylimit = 0}
$DeleteFolders += New-Object psobject -Property @{ path = "\\%PC\C$\users\%U\AppData\Roaming\Articulate\Storyline";include = "*.tmp*"; Daylimit = 0} 

# How many days old a user's profile has to be in order to automatically delete it
$UserProileLastModified = 60

# List Specific profiles to exclude from being fully deleted
$ExcludeProfiles = @{
    1 = "Public"
}

# Scans the size of these folders (no deleting)
$ScanFolders = @()
$ScanFolders += New-Object psObject -Property @{ path = "\\%PC\C$\users\%U\Appdata\local\Microsoft\outlook"}
$ScanFolders += New-Object psObject -Property @{ path = "\\%PC\C$\users\%U\Downloads"}
$ScanFolders += New-Object psObject -Property @{ path = "\\%PC\C$\users\%U\Music"}
$ScanFolders += New-Object psObject -Property @{ path = "\\%PC\C$\users\%U\Pictures"}
$ScanFolders += New-Object psObject -Property @{ path = "\\%PC\C$\users\%U\Videos"}

# Variable that halts the start of the registry cleanup
$AskBeforeDeletingRegistries = $true

# Declare registry paths here
$DeleteRegistries = @()
$DeleteRegistries += New-Object psObject -Property @{path = "HKU\%SID\Software\JavaSoft"}
$DeleteRegistries += New-Object psObject -Property @{path = "HKU\%SID\Software\Microsoft\Internet Explorer"}


<#*************************************************************************************************
#					Initialization
#************************************************************************************************#>

$OSname = (gwmi -class win32_operatingsystem).caption
$OSarchitecture = (gwmi -Query "select osarchitecture from win32_operatingsystem").OSArchitecture

$taskCompleteColor = "DarkCyan"
$notFoundColor = "Yellow"
$endOfScriptColor = "Cyan"
$foundItemColor = "Green"

$Global:TotalSizeCleared = 0


<#*************************************************************************************************
#					Functions
#************************************************************************************************#>

Function Write-LogFile{
    [CmdletBinding()]
    Param(
      #Path to the log file 
      [parameter(Mandatory=$True)] 
      [String]$LogFile, 
 
      #The information to log 
      [parameter(Mandatory=$True)] 
      [String[]]$Value, 
 
      #The source of the message 
      [parameter(Mandatory=$True)] 
      [String]$Component, 
 
      #The severity (1 - Information, 2- Warning, 3 - Error) 
      [parameter(Mandatory=$True)] 
      [ValidateSet('Information','Warning','Error')] 
      [string]$Severity,
      
      #Input a time 
      [parameter(Mandatory=$false)]
      [string]$Time,

      #input a Date
      [parameter(Mandatory=$false)]
      [string]$Date
      ) 

    Begin{
        [single]$sev = Switch($severity){
            'Information'{1}
            'Warning'{2}
            'Error'{3}
        }

        #if they are not already supplied
        if($Time.Length.Equals(0)){ $Time = Get-Date -Format "HH:mm:ss.ffffff"}
        if($Date.Length.Equals(0)){ $Date = Get-Date -Format "MM-dd-yyyy"}
 
	    if ($Component -eq $null) {$Component = " "}
	    if ($Sev -eq $null) {$Type = 1}else{$Type=$sev}
        $thread = $([Threading.Thread]::CurrentThread.ManagedThreadId)
        $context= $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)
        $file = $PSCommandPath -replace ([regex]::Escape($PSScriptRoot + '\')),''
    }
    Process{
        ForEach($logValue in $Value){
	        $LogMessage = "<![LOG[$logvalue" + "]LOG]!><time=`"$Time`" date=`"$Date`" component=`"$Component`" context=`"$context`" type=`"$Type`" thread=`"$thread`" file=`"$file`">"
	        $LogMessage | Out-File -Append -Encoding UTF8 -FilePath $LogFile
        }
    }
    End{
    }
} 


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

# Funcion that deletes items within a specifed folder, a specific comepleted string and incomplete string may be added. on default it will delete all items with
# the specified folder but that can be specified along with how old file should be. It will write all the files it deletes to the file $LogFileName.
Function Delete-ItemsInFolder {       
    [CmdletBinding()]
    Param(
        #Path to the log file 
        [parameter(Mandatory=$True)] 
        [String]$DeletePath, 
 
        #The information to log 
        [parameter(Mandatory=$false)]
        [String]$CompleteString = "Complete", 
 
        #The source of the message 
        [parameter(Mandatory=$false)]
        [String]$IncompleteString = "Could not find path", 
      
        #Input a time 
        [parameter(Mandatory=$false)]
        [string]$IncludeString = "*",

        #input a Date
        [parameter(Mandatory=$false)]
        [int]$DayLimit = 0
    ) 
        
        
    if(test-path -path $DeletePath){
        $limit = (get-date).AddDays($DayLimit)
        $TotalSize = 0
        $tempSize = 0
        $items = @()
        Write-Progress -Activity "Discovering Items" -status $DeletePath -SecondsRemaining (-1)
        
        $NumberOfItems = 0
        $Items += Get-ChildItem -path $DeletePath -include $IncludeString -Recurse -force -ErrorAction ignore | Where-Object { !$_.PSIsContainer -and $_.LastWriteTime -lt $limit } | Sort-Object -Descending Fullname| 
        foreach{
            $NumberOfItems++
            Write-Progress -Activity "Discovering Items" -status $DeletePath -currentOperation "found $NumberOfItems items" -SecondsRemaining (-1)
            $_
        }
        
        Write-Progress -Activity "Discovering Items" -Completed
        $CurrentItemNumber = 0
        if($NumberOfItems -eq 0){
            $completeString = "$DeletePath $CompleteString $TotalSize Bytes"
            Write-ToHostAndFile $completeString $taskCompleteColor
        }
        else {
            
            $Items | foreach{
                Try{
                    $CurrentItemNumber++
                    $TempSize = $_.Length
                    $TempString = $_.FullName
                    Remove-Item -path $_.Fullname -force -ErrorAction Stop
                    $TotalSize = $TotalSize + $TempSize
                    $Prefix = "Deleted "
                } 
                catch{$prefix = "Could not delete "}
            
                Write-Progress -Activity "Cleaning PC" -CurrentOperation $TempString -Status "Deleting $currentItemNumber / $numberOfItems" -PercentComplete ($CurrentItemNumber/$NumberOfItems*100)
                $TempString = $Prefix + $TempString
                if($Prefix.Equals("Deleted ")){Write-LogFile -LogFile $LogFileName -Value $TempString -Component "File" -Severity Information}
                else{Write-LogFile -LogFile $LogFileName -Value $TempString -Component "File" -Severity Warning }
            }
            $global:totalSizeCleared += $TotalSize
            $totalSize = Change-Bytes $totalSize
            $completeString = "$deletePath $completeString $totalSize"
            Write-ToHostAndFile $completeString $taskCompleteColor
        }

    }
        else{
        $IncompleteString = "$DeletePath $IncompleteString "
        Write-ToHostAndFile $IncompleteString $notFoundColor
    }
    Write-Progress -Activity "Cleaning PC" -CurrentOperation $TempString -Status $DeletePath -PercentComplete (100) -Completed
}

Function Clear-Folder{
    [cmdletBinding()]
    Param(
        [Parameter(Mandatory = $True)]
        [object]$Path,
        [string]$Filter,

        [Parameter(Mandatory = $False)]
        [string]$WhereFilter = "*",
        [int]$DaysOld = 0

    )
    Begin{
        $FileAge = (Get-Date).AddDays(-$DaysOld)
        $TotalSpaceCleared = 0
        $TempFileSize = 0
        $TempString = ""
        $Items = @()
        $NumberOfItems = 0
        $ExitString = ""
    }

    Process{
        if(Test-Path -Path $Path){
            Write-Progress -Activity "Discovering items" -Status $Path -SecondsRemaining (-1)
            $Items = Get-ChildItem -Path $Path -Filter $Filter -Recurse -ErrorAction Ignore | Where-Object {(!_.PSIsContainer) -and ($_.LastWriteTime -lt $FileAge) -and ($_.Name -like $WhereFilter)} | Sort-Object -Descending FullName
            $NumberOfItems = $Items.Count
            Write-Progress -Activity "Discovering items" -Completed
            if(!($NumberOfItems -eq 0){
                $CurrentItemNumber = 0
                Foreach($Item in $Items){
                    Try{
                        $CurrentItemNumber++
                        $TempFileSize = $Item.Length
                        $TempString = $Item.FullName
                        Remove-Item -Path $Item -Force -ErrorAction stop
                        $TotalSpaceCleared += $TempFileSize
                        $LogCode = 0
                    }
                    Catch{
                        $LogCode = 1
                    }
                    Write-Progress -Activity "Clearing Folder" -CurrentOperation $TempString -Status "Deleting $currentItemNumber / $numberOfItems" -PercentComplete ($CurrentItemNumber/$NumberOfItems*100)
                    $TempString = [string]$LogCode + " " + $TempString
                    if($LogCode -eq 1){
                        $Severity = 'Information'
                    }
                    else{
                        $Severity = 'Warning'
                    }
                    Write-LogFile -LogFile $LogFileName -Value $TempString -Component "FileDeletion" -Severity $Severity 

                }

            }
            Else{
                $ExitString = "No Items found at path $Path"
            }
        }
        Else{
            $ExitString = "Was unable to find path $Path"
        }

    }

    End{

    }

}

# Function that takes bytes and converts it to a more reasonable number with a suffix based on how large it is


# Function that will find the size of a Folder
Function Find-FolderSize ([string]$FolderPath){
    if(test-path $FolderPath){
    <#
        $size = Get-ChildItem -path $FolderPath -Recurse | Measure-Object -Property length -Sum
        Select-Object Sum
        $size = $size.Sum

        $size = change-bytes $size

        $CompleteString = "$FolderPath Folder is $size large"
        Write-ToHostAndFile $CompleteString $foundItemColor
        #>
        $Size = 0 
        Get-ChildItem -Path $FolderPath -Recurse | Where-Object {!$_.PSIsContainer} | Foreach{
            $size += $_.Length
        }
        $Size = change-bytes $Size
        $CompleteString = "$FolderPath Folder is $size large"
        Write-ToHostAndFile $CompleteString $foundItemColor
    }
    else{
        $CompleteString = "$FolderPath not found."
        Write-ToHostAndFile $CompleteString $notFoundColor
    }
}

# Function that takes a string and outputs it to the console and a txt file stored in $textColor
Function Write-ToHostAndFile ([string]$String, [string]$textColor){
    Write-host $string -ForegroundColor $textColor
    Write-LogFile -LogFile $LogFileName -Value $string -Component "Job" -Severity Information
}

#Function that will change the screen size
Function change-ScreenSize([int]$Height, [int]$Width, [int]$BufferHeight = 3000, [int]$BufferWidth = 120){
#check if it is running the ISE client before resizing screen

    $psWindow = (get-host).UI.RawUI

    try{
        if(!$psWindow.WindowSize.Equals($null)){
            $newSize = $psWindow.BufferSize
            #make sure the buffer size is larger or set it to the requested width and height
            if($BufferHeight -lt $Height){$BufferHeight = $Height}
            if($BufferWidth -lt $Width){$BufferWidth = $Width}
            $newSize.Height = $BufferHeight
            $newSize.Width = $BufferWidth
            $pswindow.BufferSize = $newSize
            
            $newSize = $psWindow.WindowSize
            $newSize.Height = $Height
            $newSize.Width = $Width
            $pswindow.windowSize = $newSize
        }
    }

    catch{Write-Warning "In ISE environment, skipping the resizing of the window."}
}

#Function that retrieves the SID of a user.
Function get-UserSid{

    [CmdletBinding()]
    Param(
      #username
      [parameter(Mandatory=$True)] 
      [String]$User 
    )

    return (Get-ADUser $user).sid.value
}

function Delete-RegistryFolder([string]$DeletePath,[string]$PC){
<#
.SYNOPSIS

Deletes a registry folder and its contents on a specified PC and user profile.

.DESCRIPTION

Deletes a registry folder and its contents on a specified PC and user profile.
It will output a log file with a time stamp to the local sessions C:\temp folder showing all the keys deleted
aswell as the order it was deleted.
The user profile is converted to its SID number which is used in the delete path.
be sure to only specify the part of the path that comes after the SID.

.PARAMETER DeletePath
Specifies the path to the folder you want deleted.

.PARAMETER PC
Specifies the target PC

.PARAMETER User
Specifies the user profile to targe

.INPUTS
None. You cannot pipe objects to Delete-RegistryFolder.

.OUTPUTS

Appends to a log file to show what registries were deleted

#>

    
    $DeletePath = "Registry::" + $DeletePath
    if(Test-Path $DeletePath){
    
    $Log = Invoke-Command -ComputerName $PC -ArgumentList $DeletePath -ScriptBlock  {
        Push-Location registry::
        #initialize variables
        $DeletePath = $args[0]
        $Log = @()
        Get-ChildItem -Path $DeletePath -recurse -force| Sort-Object -Descending name |
        foreach{
                Try{        
                    $TempString = $_.name
                    Remove-Item $_ -force
                    $TempString = "Deleted " + $TempString
                } 
                catch{
                    $TempString = "Could not delete " + $TempString
                }
                #variable for storing the log files.
                $Log += $TempString
        }
        #remove folder
        $Log += "Completed " +$DeletePath
        remove-item -path $DeletePath -Recurse
        Pop-Location

        #Pass variable back to the local session
        $Log
    }
    #log files
    $log | foreach{
        Write-LogFile -LogFile $LogFileName -Value $_ -Component "Registry" -Severity Information
        }

        Write-ToHostAndFile -String "$DeletePath cleaned." -textColor $taskCompleteColor
        }
    else{
        Write-ToHostAndFile -string "$DeletePath not found." -textColor $notFoundColor
    }
    
}

function get-LoggedOnUsers([string]$PCName){
    $user = GWMI -Class win32_computersystem -ComputerName $PCName | select username
    if($user.username.Length -eq 0){
        $user = "No User logged in"
    }
    else{
        $user = $user.username
    }
    return $user
}

function write-softWarning{

    [CmdletBinding()]
    Param(
      #username
      [parameter(Mandatory=$True)] 
      [String]$str 
    )

    write-host $str -ForegroundColor Yellow

}

<#**************************************************************************************************
#					Main
#**************************************************************************************************#>


# Change the screen size to make it more readable
change-ScreenSize -Height 40 -Width 150

if(($args.Count -ne 0) -and ($args[0] -ne "-Command")){
    <#
    $ResourceID = $args[0]
    $Server = $args[1]
    $Namespace = $args[2]

    $strQuery = "Select ResourceID,ResourceNames from SMS_R_System where ResourceID='$ResourceID'"
    Get-WmiObject -Query $strQuery -Namespace $Namespace -ComputerName $Server | ForEach-Object {$PCName = $_.ResourceNames[0]}

    $PCName = $PCName.TrimEnd(".abcp.bluecross.ca")
    #>
    $PCName = $args[0]
}
else{
    # Prompt for a pc name
    $pcName = Read-Host -Prompt "Please enter the PC name"

    while($true){
        try{
           $PCAD = Get-ADComputer $pcName -ErrorAction Stop
           break
        }
        catch{
           Write-Host "PC name not valid" -ForegroundColor Red
           $pcName = Read-Host -Prompt "Please enter the PC name (Enter to Stop)"
           if($pcName -eq ""){Write-Host "Script stopped" -ForegroundColor $endOfScriptColor
           Read-host "Press enter to close window"
           exit }
        }
    }
}


# check if you can connect to the C drive
if(!(test-path -path \\$pcName\c$)){
    Write-warning "can't connect to C drive, stopping" -ForegroundColor Red
    Read-host "Press Enter to close window"
    exit
}

if($AskBeforeStarting){
    $Pause = read-host "would you like to clean PC $PCname`? [Y]"
    $Pause = $Pause.ToLower()
    if($Pause -ne "y"){
        read-host "Script stopped, press enter to close window."
        exit
    }
}

$PCName = $PCName.ToUpper()

# Generate Log file and transcript file name
$LogFileName = Get-Date -uFormat "-%Y-%m-%d-T%H%M"
$transcriptName = "C:\temp\" + $pcName + $LogFileName + "_Transcript.txt"
$LogFileName = "C:\temp\" + $pcName + $LogFileName + "_cleanup.log"

# Prompt for a username
$currentUsername = Read-Host -Prompt "Please enter the users profile"

while(!(test-path -path \\$pcName\c$\users\$currentUsername)){
    Write-Host "Username not found on PC ", $pcName -ForegroundColor Red
    $CurrentUsername = Read-Host -Prompt "Please enter the username (Enter to Stop)"
    if($CurrentUsername -eq ""){Write-Host "Script stopped" -ForegroundColor $endOfScriptColor
    Read-host "Press enter to close window."
    exit }
}


# Find out the current disk space
$StartingDiskSpace = Get-FreeDiskSpace -PCName $PCname

# Loop through all the folders to be deleted
for($i = 0; $i -lt $DeleteFolders.Count; $i++){
    $DeleteFolders[$i].path = $DeleteFolders[$i].path.Replace("%PC",$PCName)
    $DeleteFolders[$i].path = $DeleteFolders[$i].path.Replace("%U",$currentUsername)
    Delete-ItemsInFolder -DeletePath $DeleteFolders[$i].path -IncludeString $DeleteFolders[$i].include -DayLimit $DeleteFolders[$i].Daylimit
}


# Loop throught all the registry paths to be deleted
if($AskBeforeDeletingRegistries){
    $Pause = read-host "Would you like to clean the registry of PC $PCname`? [Y]"
    $Pause = $Pause.ToLower()
    if($Pause -ne "y"){
        Write-ToHostAndFile -String "Skipped Cleaning registry" $taskCompleteColor
    }
    else{
        for($i = 0; $i -lt $DeleteRegistries.Count; $i++){
            $SID = get-UserSid -User $currentUsername
            $DeleteRegistries[$i].path = $DeleteRegistries[$i].path.Replace("%SID", $SID)
            Delete-RegistryFolder -DeletePath $DeleteRegistries[$i].path -PC $PCName
        }
    }
}
else{
    for($i = 0; $i -lt $DeleteRegistries.Count; $i++){
        $SID = get-UserSid -User $currentUsername
        $DeleteRegistries[$i].path = $DeleteRegistries[$i].path.Replace("%SID", $SID)
        Delete-RegistryFolder -DeletePath $DeleteRegistries[$i].path -PC $PCName
    }
    $DeleteRegistryScript
}

# Loop through all the folders to be scanned
for($i = 0; $i -lt $ScanFolders.Count ; $i++){
    $ScanFolders[$i].path = $ScanFolders[$i].path.Replace("%PC",$pcName)
    $ScanFolders[$i].path = $ScanFolders[$i].path.Replace("%U",$currentUsername)
    Find-FolderSize -FolderPath $ScanFolders[$i].path
} 

#Get new Disk space
$AfterDiskSpace = Get-FreeDiskSpace -PCName $PCName

$AfterDiskSpace = Change-Bytes $AfterDiskSpace

# End of Script 
$Global:TotalSizeCleared = Change-Bytes $Global:TotalSizeCleared
$String = $global:totalSizeCleared + " of space have been cleared from PC " + $pcname + " leaving a total of " + $AfterDiskSpace, "
Script complete, Log File in C:\temp"
Write-ToHostAndFile $string $endOfScriptColor

Start-Sleep -Seconds 1
Read-Host -Prompt "Press Enter to close window"

Remove-Variable currentUsername, pcname