<#
Script for retrieving IMEIs, Phone Number, and Sim cards


the Two commands we can use is 
netsh mbn show readyinfo interface="Mobile Broadband Connection"  
netsh mbn show interface 
 

 I will try to see if there a wmi object equivalent for these. After some research, it does not appear to be provided by WMI

PS C:\WINDOWS\system32> $stuff = invoke-command -ComputerName XXXXXXXX -scriptblock {netsh mbn show interface}
PS C:\WINDOWS\system32> $stuff

Device ID is the IMEI
There is 1 interface on the system:

    Name               : Mobile Broadband Connection
    Description        : DW5811e Snapdragon(TM) X7 LTE
    GUID               : {EC5BFD14-74DC-4D68-9378-77DF840C9FA3}
    Physical Address   : 00:a0:c6:00:00:04
    State              : Not connected
    Device type        : This is a remote device
    Cellular class     : GSM
    Device Id          : XXXXXXXXXXXXXX
    Manufacturer       : Sierra Wireless, Incorporated
    Model              : EM7455B
    Firmware Version   : SWI9X30C_02.20.03.00
    Provider Name      :
    Roaming            : Not roaming
    Signal             : 100%
    RSSI / RSCP        : 31 (-51 dBm)

    SIM ICC Id is the Sim Card
    Telephone is the Phone number

    PS C:\WINDOWS\system32> $stuff = invoke-command -ComputerName XXXXXXX -scriptblock {netsh mbn show readyinfo interface="
Mobile Broadband Connection"}
PS C:\WINDOWS\system32> $stuff

Ready information for interface Mobile Broadband Connection:
-------------------------------------
    State            : Ready to power up and register
    Emergency mode   : Off
    Subscriber Id    : XXXXXXXXXXXXXXXX
    SIM ICC Id       : XXXXXXXXXXXXXXXXXXXXX
    Number of telephone numbers  : 1
        Telephone #1             : XXXXXXXXXX


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
$TempFile = '7270List.XML'
Write-LogFile -LogFile $logfile -Value "found CSV $CSV" -Component Information -Severity Information

if(!(test-path (join-path -path $PSSCriptRoot -childpath $TempFile))){
    
    $computersCSV = Get-Content -Path $CSV
    $computerProperties = $computersCSV[0].Split(';').Replace("`"","").Replace(" ","")
    $dictionary = @{}
    $dictionary.Add('Pinged', $False)
    $dictionary.Add('ScanIMEI', $null)
    $dictionary.Add('ScanSIMCard', $null)
    $dictionary.Add('ScanIPAddress', $null)
    $dictionary.Add('ScanPhoneNumber', $null)
    $dictionary.Add('LastAttempt',$null)

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

$Computers = $ComputersInformation | ? { $_.Pinged -eq $False} | select ComputerName


Foreach($Computer in $Computers){
    $computer = $computer.Computername
    $ScanIPAddress = (Test-Connection -ComputerName $Computer -Count 1 -ErrorAction Ignore).IPV4Address.IPAddressToString
    $ScanIMEI = 'Unpingable'
    $ScanSIM = 'Unpingable'
    $ScanPhoneNumber = 'Unpingable'
    $pinged = $false
    write-host "...working on $computer"
    if(Test-Connection -ComputerName $Computer -Quiet){
        
        Write-LogFile -LogFile $logfile -Value "Pinged Computer $computer." -Component Information -Severity Information
        
        $Information = Invoke-Command -ComputerName $Computer -ScriptBlock {netsh mbn show interface
            netsh mbn show readyinfo interface="Mobile Broadband Connection"
            } -ErrorAction Ignore
            if($information){
                $pinged = $True
                Write-host "Success"
                
            }
            Else{Write-LogFile -LogFile $logfile -Value "Win RM problem on $computer." -Component Information -Severity Information}
        $information = $Information.split("`n")
        $ScanIMEI = $information | Where-object {$_ -like "*Device ID*"} | Foreach {$_.split(":").trim()[1]}
        $ScanSIM = $information | Where-object {$_ -like "*SIM ICC id*"} | Foreach {$_.split(":").trim()[1]}
        $ScanPhoneNumber = $information | Where-object {$_ -like "*Telephone #*"} | Foreach {$_.split(":").trim()[1]}
    }
    Else{Write-LogFile -LogFile $logfile -Value "Unable to Ping $Computer." -Component Information -Severity Information; Write-host "Failed"}
    
    $ComputersInformation | ? {$_.ComputerName -eq $computer} | %{$_.ScanIMEI = $ScanIMEI
        $_.ScanSimCard = $ScanSIM
        $_.ScanPhoneNumber = $ScanPhoneNumber
        $_.Pinged = $pinged
        $_.ScanIPAddress = $ScanIPAddress
        $_.LastAttempt = get-date
        }
}

Write-LogFile -LogFile $logfile -Value "Exported XML $tempFile" -Component Information -Severity Information
Export-Clixml -Path (Join-Path -path $PSScriptRoot -ChildPath $TempFile) -InputObject $computersInformation