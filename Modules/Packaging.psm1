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

