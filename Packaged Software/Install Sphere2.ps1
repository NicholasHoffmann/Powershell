#**************************************************************************************************
# FILENAME:			Install Sphere2.ps1
# DESCRIPTION:		Install the newest version of Sphere2 Aver U50 Portable Camera Software
# REFERENCE:		
#
# VERSION			1.0
# DATE:             November 27th 2018
# AUTHOR:           Nicholas Hoffmann
# COMMENTS:         Initial Release
#
# VERSION
# DATE:
# AUTHOR:
# COMMENTS:
#			
#
# VERSION		
# DATE:			
# AUTHOR:		
# COMMENTS:		
# 
# FYI:
# You can run the sample line below to get Add Remove Program Data on a system with SCCM installed - this displays info such as SoftwareCode, etc.
# $Snow=gwmi -query "select * from sms_installedsoftware where arpdisplayname like '%sphere%'" -namespace "root\cimv2\sms"
#
#*************************************************************************************************************************************************
#					Initialization
#***********************************************************************************************************************************************#>
#Powershell version 2 doesn't use the PSScriptRoot variable
If(!($PSScriptRoot)){
     $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
}

#Version
#A+_Suite_for_Win_v2.5.2140.141
$strVersionNumber = "2.5.2140.141"

#Snow MSI
$MSI = "$PSScriptRoot\A+_Suite_for_Win_v2.5.2140.141.msi"

#OS Architecture
$osArchitecture = (gwmi -Query "select osarchitecture from win32_operatingsystem" | select -ExpandProperty "OSArchitecture")

#Log File
$LogFile = "C:\Windows\Temp\ABC - Sphere2 $strVersionNumber.log"

#*************************************************************************************************************************************************
#					Functions
#***********************************************************************************************************************************************#>
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
      [string]$Severity 
      ) 
    Begin{
        [single]$sev = Switch($severity){
            'Information'{1}
            'Warning'{2}
            'Error'{3}
        }
  
        $Time = Get-Date -Format "HH:mm:ss.ffffff"
           $Date = Get-Date -Format "MM-dd-yyyy"

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
Function UnInstall-Software{
<#
.SYNOPSIS
Uninstalls MSI based software

.DESCRIPTION
Uninstalls MSI based software with specified filters

.PARAMETER ARPDisplayName
The name of the program to uninstall.  Use % signs for wildcard filters

.PARAMETER ARPVersion
The Version of the program to uninstall...OR....The first version to keep (all previous versions removed)

.PARAMETER VersionBehavior
Whether or not to remove specified version or versions before specified version

.PARAMETER Publisher
Publisher of program to uninstall. Use % signs for wildcard filters

#>
    [CmdletBinding()] 
    Param( 
        #Add Remove Programs DisplayName
        [parameter(Mandatory=$True)] 
        [String]$ARPDisplayName, 
 
        #Specific Version
        [parameter(Mandatory=$false)]
        [Version]$ARPVersion = $null, 
        
        #Version Behavior
        [parameter(Mandatory=$false)]
        [ValidateSet('UninstallPrevious','UninstallVersion')]
        [string]$VersionBehavior,

        #Publisher match
        [parameter(Mandatory=$false)]
        [string]$Publisher = $null


    )
    Begin{
        #Exit if bad params
        if($versionbehavior -and (!$ARPVersion)){
            Throw "VersionBehavior can only be used in conjunction with ARPVersion"
            Return
        }
        $query = "Select * from SMS_InstalledSoftware where ARPDisplayName like `"${ARPDisplayName}`""
        if($ARPVersion -and $VersionBehavior -eq 'UninstallVersion'){
            $query += " and ProductVersion=`"${ARPVersion}`""
        }
        if($Publisher){
           $query += " and Publisher like `"${Publisher}`""
        }
    }Process{
        #Get Software
        $arrSoftware = gwmi -query $query -Namespace "root\CIMV2\sms"

        #Filter software based on version
        if($VersionBehavior -eq 'UninstallPrevious'){
            $arrSoftware = $arrSoftware | Where{[version]$_.ProductVersion -lt $ARPVersion}
        }

        #Uninstall all software returned
        $exitcodes = @()
        ForEach($objSoftware in $arrSoftware){
            $softwarecode = $objSoftware.SoftwareCode
            $args = "/x ${softwarecode} /qn /lv* `"C:\Windows\Temp\Uninstall-${arpdisplayname}${ARPVersion}.log`" /qn"
            $objReturn = Start-Process 'msiexec' -ArgumentList $args -PassThru -Wait

            $objStatus = [pscustomobject]@{
                'DisplayName'=$objSoftware.arpdisplayname;
                'Version'=$objSoftware.ProductVersion;
                'ProductCode'=$objSoftware.SoftwareCode;
                'Publisher'=$objSoftware.Publisher;
                'ExitCode'=$objReturn.ExitCode;

            }
            $exitcodes += $objStatus
        }

    }End{
        Return $exitcodes
    }
} 

#*************************************************************************************************************************************************
#					Main
#***********************************************************************************************************************************************#>
# Uninstall old A+ Suite.
Write-LogFile -LogFile "$LogFile" -Value "Uninstalling previous A+ Suite" -Component Uninstall -Severity Information
$arrExitObjects = UnInstall-Software -ARPDisplayName 'A+ Suite'
ForEach($exitObject in $arrExitObjects){
    $displayname = $exitObject.DisplayName
    $version = $exitObject.Version
    $exitcode = $exitObject.Exitcode
    Write-LogFile -LogFile $LogFile -Value "Completed uninstalling $displayname version $version with exitcode: $exitcode.  For more information see: `"C:\Windows\Temp\Uninstall-${displayname}${version}.log`"" -Component Uninstall -Severity Information
} 

# Run the install of the new Version.
Write-LogFile -LogFile "$LogFile" -Value "Beginning install of Sphere2 $strVersionNumber" -Component Install -Severity Information
$args = "/i $MSI /qn /lv* C:\Windows\Temp\Install-Sphere2-$strVersionNumber.log"

$ObjReturn = Start-Process "msiexec.exe" -argumentlist $args -Wait -PassThru

$exitcode = $ObjReturn.ExitCode
Write-LogFile -LogFile "$LogFile" -Value "Installed Sphere2 $strVersionNumber with exitcode: $exitcode. For more information see: `"C:\Windows\Temp\Install-Sphere2-$strVersionNumber.log`"" -Component Install -Severity Information

# Remove unwanted shortcuts in the start menu and Public Desktop
Get-Childitem "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\AVer Information Inc\A+ Suite" -Recurse -Exclude 'Sphere2.lnk' | Sort-object Fullname -Descending | % { Write-LogFile -LogFile $LogFile -Value $_.FullName -Component Delete -Severity Information;$_.Delete()} 
Get-ChildItem "C:\Users\Public\Desktop\AVerVision Flash Plug-in.swf.lnk" | % { Write-LogFile -LogFile $LogFile -Value $_.FullName -Component Delete -Severity Information;$_.Delete()}
Get-ChildItem "C:\Users\Public\Desktop\Sphere2.lnk" | % { Write-LogFile -LogFile $LogFile -Value $_.FullName -Component Delete -Severity Information;$_.Delete()} 

# Uninstall A + Suite Product Update
Write-LogFile -LogFile "$LogFile" -Value "Uninstalling A+ Suite Product Update from add remove programs." -Component Uninstall -Severity Information
C:\Windows\system32\sdbinst.exe -u "C:\WINDOWS\AppPatch\CustomSDB\{576bc437-4dd1-4d5e-bf4d-c1687e692286}.sdb" | % { Write-LogFile -LogFile "$LogFile" -Value $_ -Component Uninstall -Severity Information}

$ObjReturn.ExitCode

