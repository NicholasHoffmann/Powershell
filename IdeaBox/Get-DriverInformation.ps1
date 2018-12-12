<#
Script for retrieving Driver Information

using gwmi -query "select * from Win32_PNPSignedDriver" we can get all the drivers and any information

Here is what the Wireless Driver looks like
__GENUS                 : 2
__CLASS                 : Win32_PnPSignedDriver
__SUPERCLASS            : CIM_Service
__DYNASTY               : CIM_ManagedSystemElement
__RELPATH               : 
__PROPERTY_COUNT        : 28
__DERIVATION            : {CIM_Service, CIM_LogicalElement, CIM_ManagedSystemElement}
__SERVER                : 4500PN2
__NAMESPACE             : root\cimv2
__PATH                  : 
Caption                 : 
ClassGuid               : {4d36e972-e325-11ce-bfc1-08002be10318}
CompatID                : PCI\VEN_8086&DEV_24FD&REV_78
CreationClassName       : 
Description             : Intel(R) Dual Band Wireless-AC 8265
DeviceClass             : NET
DeviceID                : PCI\VEN_8086&DEV_24FD&SUBSYS_01508086&REV_78\34415DFFFF33CFE800
DeviceName              : Intel(R) Dual Band Wireless-AC 8265
DevLoader               : 
DriverDate              : 20171023000000.******+***
DriverName              : 
DriverProviderName      : Intel
DriverVersion           : 20.10.1.3
FriendlyName            : Intel(R) Dual Band Wireless-AC 8265
HardWareID              : PCI\VEN_8086&DEV_24FD&SUBSYS_01508086&REV_78
InfName                 : oem47.inf
InstallDate             : 
IsSigned                : True
Location                : PCI bus 1, device 0, function 0
Manufacturer            : Intel Corporation
Name                    : 
PDO                     : \Device\NTPNP_PCI0020
Signer                  : Microsoft Windows Hardware Compatibility Publisher
Started                 : 
StartMode               : 
Status                  : 
SystemCreationClassName : 
SystemName              : 
PSComputerName          : 4500PN2

The Properties we will keep are

ClassGuid
CompatID
Description
DeviceClass
DeviceID
DeviceName
DriverDate (I will format this into a more readable format)
DriverProviderName
DriverVersion
FriendlyName
HardwareID
InfName
isSigned
Location
Manufacturer
Signer

Which will make the query 
gwmi -query "select ClassGuid,CompatID,Description,DeviceClass,DeviceID,DeviceName,DriverDate,DriverProviderName,DriverVersion,FriendlyName,HardwareID,InfName,isSigned,Location,Manufacturer,Signer from Win32_PNPSignedDriver"

Total is 16 properties plus whatever is the original CSV


#>


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



$CSV = (Get-ChildItem -Path $PSScriptRoot -Include *.CSV -Recurse)[0]
$logfile = Join-Path $PSScriptRoot -ChildPath 'ScanLogs.Log'
$CompletedLogFile = Join-path $PSScriptRoot -ChildPath 'CompletedScans.Log'
$TempFile = '7270List.XML'
Write-LogFile -LogFile $logfile -Value "found CSV $CSV" -Component Information -Severity Information



if(!(test-path (join-path -path $PSSCriptRoot -childpath $TempFile))){
    
    $computersCSV = Get-Content -Path $CSV
    $computerProperties = $computersCSV[0].Split(';').Replace("`"","").Replace(" ","")
    $dictionary = @{}
    $dictionary.Add('Complete', $False)
    $dictionary.Add('Drivers',@())
    $dictionary.Add('Bios',@())

    foreach($Property in $computerProperties){
        $dictionary.Add($Property,$null)
    }

    $computersInformation = @()

    for($i = 1; $i -lt $computersCSV.Count; $i++){
        $computer = $computersCSV[$i].Split(';').Replace("`"","")
        for($h = 0; $h -lt $computerProperties.count; $h++){
            $dictionary.($computerProperties[$h]) = $computer[$h]
        }
        $computersInformation += New-Object psObject -Property $dictionary
    }
    Export-Clixml -Path (Join-Path -path $PSScriptRoot -ChildPath $TempFile) -InputObject $computersInformation
    Write-LogFile -LogFile $logfile -Value "generated new XML $tempFile" -Component Information -Severity Information
}


$ComputersInformation = Import-Clixml -Path (Join-Path -path $PSScriptRoot -ChildPath $TempFile)
Write-LogFile -LogFile $logfile -Value "imported XML $tempFile" -Component Information -Severity Information

$Computers = $ComputersInformation | ? { $_.Complete -eq $False} | select ComputerName

$PropertyCSV = 'ClassGuid,CompatID,Description,DeviceClass,DeviceID,DeviceName,DriverDate,DriverProviderName,DriverVersion,FriendlyName,HardwareID,InfName,isSigned,Location,Manufacturer,Signer'

Foreach($Computer in $Computers){
    $computer = $computer.Computername
    $Pinged = $false


    write-host "...working on $computer"
    if(Test-Connection -ComputerName $Computer -Quiet){
        
        Write-LogFile -LogFile $logfile -Value "Pinged Computer $computer." -Component Information -Severity Information
        
        $Information = GWMI -query "select $PropertyCSV from Win32_PNPSignedDriver" -ComputerName $Computer -ErrorAction Ignore
            if($information){
                $pinged = $True
                Write-host "Success"
                $biosVersion = (gwmi win32_bios -ComputerName $computer).name
                $information = $Information | select $PropertyCSV.Split(",")  | ? {$_.Description -ne $null} # this filters out the unwanted properties and gets rid of anything without a description
                
                
                Write-LogFile -LogFile $logfile -Value "Completed $computer." -Component Information -Severity Information
                Write-LogFile -LogFile $Completedlogfile -Value "Completed $computer." -Component Information -Severity Information
            }

            Else{Write-LogFile -LogFile $logfile -Value "Win RM problem on $computer." -Component Information -Severity Information;Write-host "WinRM problem"}

    }
    Else{Write-LogFile -LogFile $logfile -Value "Unable to Ping $Computer." -Component Information -Severity Information; Write-host "Failed"}
    
    $ComputersInformation | ? {$_.ComputerName -eq $computer} | %{$_.Drivers = $information
    $_.Complete = $Pinged
    $_.bios = $biosVersion}
}

Write-LogFile -LogFile $logfile -Value "Exported XML $tempFile" -Component Information -Severity Information
Export-Clixml -Path (Join-Path -path $PSScriptRoot -ChildPath $TempFile) -InputObject $computersInformation