

Function Translate-OU{
    #Basic function that turns the comma seperated OU in distinguished name to an easier format \ \ \
    [cmdletBinding()]
    Param(
        [Parameter(Mandatory = $True)]
        $DistinguishedName
    )

    $Str = $DistinguishedName.SubString($DistinguishedName.IndexOf("OU=")-1)
    #$Str = $Str.Substring(0,$Str.IndexOf("DC=")-1)
    $Str = $Str.Replace(",DC=",".")
    $Str = $Str.Replace(",OU=","\")
    $str = $Str.Substring(1)

    Return $Str

}

Function Get-StandardADAccounts{
    [cmdletBinding()]
    
    Param(
        [Parameter(Mandatory = $False)]
        $ADProperties
    )
    
    Write-Verbose "Properties defined are $ADProperties"
    #The filters are as followed
    #A regular user has an employeeID
    #A contractor does not have an employeeID so we will use Title has the word contractor
    #The User is not disabled (deactivated)
    $ADUsers = Get-ADUser -Filter {((EmployeeID -ne 0) -or (Title -like "*Contractor*")) -and (Enabled -eq $True)} -Properties $ADProperties
    
    Return $ADusers
    
    }

    Function Get-ADComputerMemberOf{
        [cmdletBinding()]
        Param(
            [Parameter(Mandatory = $False)]
            [object]$ComputerName = $ENV:ComputerName
        )
        Begin{
    
        }
    
        Process{
            Try{
                $MemberOf = (Get-AdComputer $ComputerName -Properties MemberOf).MemberOf
                $FormattedMembers = @()
                Foreach($Member in $MemberOf){
                    $TempStr = $Member.split(",")[0].TrimStart("CN=")
                    $FormattedMembers += $TempStr
                }
                $FormattedMembers = $FormattedMembers | Sort-Object
                Return $FormattedMembers
            }
            Catch{
                Write-Error -Message "Computer not found in Active Directory"
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

Function Get-MacAddress{
    <#
     .Synopsis
        Retrieves the mac addresses of a computer.
    
     .Description
        Retrieves the mac addresses of a computer by quering WMI.
    
     .Parameter ComputerName
        The name of the computer, leave blank for host computer
    
     .Parameter Properties
        The properties to extract from WMI
    
     .Example
        Get-MacAddress -ComputerName 'Server01'
    
    #>
    
        [CmdletBinding()]
        Param(
            [Parameter(Mandatory = $False, ValueFromPipeline = $True)]
            [Object]$ComputerName = $ENV:ComputerName,
            [Parameter(Mandatory = $False)]
            [String]$Properties = "AdapterType,MacAddress,ServiceName,NetConnectionID"
        )
    
        Begin{}
    
        Process{
            if(Test-Connection -ComputerName $ComputerName -Count 2 -Quiet){
                Try{
                    $Selection = $Properties.Split(",")
                    $NetworkAdapters = Get-WmiObject -Query "Select $Properties From Win32_NetworkAdapter" -ComputerName $ComputerName | Select-Object $Selection | Where-Object {$_.AdapterType -eq 'Ethernet 802.3'}
                }
                Catch{
                    Write-Verbose "Was unable to query $ComputerName's WMI"
                    Return 2
                }
            }
            Else{
                Write-Verbose "Was unable to ping $ComputerName."
                Return 1
            }
        }
        End{
            Return $NetworkAdapters
        }
    }

    Function Get-MonitorInformation{
        [cmdletBinding()]
        Param(
            [Parameter(Mandatory = $False, ValueFromPipeline = $True)]
            [object]$ComputerName = $ENV:COMPUTERNAME,
            [parameter(Mandatory = $False)]
            [String]$Properties = "ManufacturerName,ProductCodeID,SerialNumberID,UserFriendlyName,WeekOfManufacture,YearOfManufacture"
        )
        if(Test-Connection -ComputerName $ComputerName -Count 2 -Quiet){
            Try{
                $WMIMonitor = Get-WmiObject -Namespace Root\WMI -Query "Select $Properties From WMIMonitorID" -ComputerName $ComputerName
                $MonitorInformation = @()
                $Count = 1
                
                Foreach($Instance in $WMIMonitor){
                    $Object = New-object -TypeName PSobject -Property @{
                        ManufacturerName = ''
                        ProductCodeID = ''
                        SerialNumberID = ''
                        UserFriendlyName = ''
                        DateOfManufacture = ''
                        Count = 0
                    }
                    $Instance.ManufacturerName  | ForEach-Object{$Object.ManufacturerName += [char]$_}
                    $Instance.ProductCodeID     | ForEach-Object{$Object.ProductCodeID += [char]$_}
                    $Instance.SerialNumberID    | ForEach-Object{$Object.SerialNumberID += [char]$_}
                    $Instance.UserFriendlyName  | ForEach-Object{$Object.UserFriendlyName += [char]$_}
                    $TempDate = Get-Date -Year $Instance.YearOfManufacture -Month 1 -Day 1 -Hour 0 -Minute 0 -Second 0 -Millisecond 0
                    $TempDate = $TempDate.AddDays(7*$Instance.WeekOfManufacture)
                    $Object.DateOfManufacture = $TempDate
                    $Object.Count = $Count
                    $Count++
    
                    $MonitorInformation += $Object
    
                }
    
                return $MonitorInformation
            }
            Catch{
                Write-Verbose "Failed to query WMI on machine $ComputerName"
                Return 2
            }
        }
        Else{
            Write-Verbose "Failed to Ping machine $ComputerName"
            Return 1
        }
    
    }

    Function Get-PhysicalMemoryCapacity{
        [cmdletBinding()]
        Param(
            [Parameter(Mandatory = $False, ValueFromPipeline = $True)]
            [object]$ComputerName = $ENV:ComputerName
    
        )
        Begin{
            $Query = "Select Capacity from Win32_PhysicalMemory"
            $Namespace = "Root\CimV2"
        }
    
        Process{
            $Capacity = $Null
            if(Test-Connection -ComputerName $ComputerName -Count 2 -Quiet){
                Try{
                    $Capacity = (Get-WmiObject -ComputerName $ComputerName -Query $Query -Namespace $Namespace | Measure-Object -Property Capacity -Sum).Sum
                    $Capacity = $Capacity/[Math]::Pow(1024,3)
                }
                Catch{
                    Write-Error -Message "Unable to Query WMI on Computer $ComputerName"
                }
            }
            Else{
                Write-Error -Message "Unable to ping Computer $ComputerName"
            }
        }
    
        End{
            Return $Capacity
        }
    }
    