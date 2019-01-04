############################################
# Functions
############################################

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