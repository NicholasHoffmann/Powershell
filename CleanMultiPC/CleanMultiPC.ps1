 <#**************************************************************************************************
' FILENAME:			Operational - Multi Workstation Cleanup.ps1
' DESCRIPTION:		Complete script for workstation cleanup.
' REFERENCE:	
' Copyright 2018, Nicholas Hoffmann, All rights reserved.
' This script is a branch off of the original cleanPC script that has been modified to work on a list of PCs.
'   
#>

<#
' VERSION			0.1Alpha
' DATE:				July 16th, 2018
' AUTHOR:			Nicholas Hoffmann
' COMMENTS:			Initial Release
'
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

# Function to get free disk space
Function Get-FreeDiskSpace{
    [CmdletBinding()]
    Param(
      # Name of the PC 
      [parameter(Mandatory=$True)] 
      [String]$PCName,

      [parameter(Mandatory=$False)]
      [String]$Drive = "C:"
    )
    return (GWMI Win32_LogicalDisk -ComputerName $PCName -Filter "DeviceID='$Drive'").FreeSpace
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

# Function that takes bytes and converts it to a more reasonable number with a suffix based on how large it is
Function Change-Bytes ([float]$value){
    $count = 0
    while(($value -gt 1024) -or ($value -lt -1024)){
        $value = $value/1024
        $count++
    }
    $value = [system.math]::Round($value,2)
    
    switch($count){
        0{$Suffix = "bytes"}
        1{$Suffix = "Kilobytes"}
        2{$Suffix = "Megabytes"}
        3{$Suffix = "Gigabytes"}
        4{$Suffix = "Terabytes"}
        5{$Suffix = "Petabytes"}
        6{$Suffix = "Exabytes"}
        7{$Suffix = "Zetabytes"}
        default{$Suffix = "BigBoys"}
    }

    $ReturnValue = "$value $suffix"
    return $ReturnValue
}


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
#Computers = Get-Content -Path (Join-Path -Path $PSScriptRoot -ChildPath "\PCs to clean.txt")
$computers = 'ddxdj02'


ForEach($PCName in $Computers){
    # check if you can connect to the C drive
        $PCName = $PCName.ToUpper()
        $Global:TotalSizeCleared = 0
        # Generate Log file and transcript file name
        $LogFileName = Get-Date -uFormat "-%Y-%m-%d-T%H%M"
        $LogFileName = "C:\temp\" + $pcName + $LogFileName + "_cleanup.log"

    if(!(test-path -path \\$pcName\c$)){
        #Write-warning "can't connect to C drive of $PCName"
        Write-ToHostAndFile "Can't connect to C Drive of $PCName" -textColor $notFoundColor
        continue
    }
    else{

        # Prompt for a username
        $users = @()
        Get-ChildItem -Path \\$PCName\C$\users\ | Select-Object Name | Foreach{$users += $_.name}
    
        Foreach($currentUsername in $users){
            # Find out the current disk space
            $StartingDiskSpace = Get-FreeDiskSpace -PCName $PCname

            # Loop through all the folders to be deleted
            for($i = 0; $i -lt $DeleteFolders.Count; $i++){
                $CurrentPath = $DeleteFolders[$i].path.Replace("%PC",$PCName)
                $CurrentPath = $CurrentPath.Replace("%U",$currentUsername)
                Delete-ItemsInFolder -DeletePath $CurrentPath -IncludeString $DeleteFolders[$i].include -DayLimit $DeleteFolders[$i].Daylimit
            }

            # Loop through all the folders to be scanned
            for($i = 0; $i -lt $ScanFolders.Count ; $i++){
                $CurrentPath = $ScanFolders[$i].path.Replace("%PC",$pcName)
                $CurrentPath = $CurrentPath.Replace("%U",$currentUsername)
                Find-FolderSize -FolderPath $CurrentPath
            } 
        }

        #Get new Disk space
        $AfterDiskSpace = Get-FreeDiskSpace -PCName $PCName

        $AfterDiskSpace = Change-Bytes $AfterDiskSpace

        # End of Script 
        $Global:TotalSizeCleared = Change-Bytes $Global:TotalSizeCleared
        $String = $global:totalSizeCleared + " of space have been cleared from PC " + $pcname + " leaving a total of " + $AfterDiskSpace, "
        Script complete, Log File in C:\temp"
        Write-ToHostAndFile $string $endOfScriptColor
    }

}

Start-Sleep -Seconds 1
Read-Host -Prompt "Press Enter to close window"

Remove-Variable currentUsername, pcname