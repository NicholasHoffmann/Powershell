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
            $WMIMonitor = Get-WmiObject -Namespace Root\WMI -Query "Select $Properties From WMIMonitorID"
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

