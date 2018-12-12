 <#**************************************************************************************************
' FILENAME:			GetMonitors.ps1
' DESCRIPTION:		This script takes in PC names and outputs all the monitors associated with those PCs.
' REFERENCE:	
' Copyright 2018, Nicholas Hoffmann, All rights reserved.
'
'
#>

<#
' VERSION			0.1Alpha
' DATE:				July 18th, 2018
' AUTHOR:			Nicholas Hoffmann
' COMMENTS:			
'
'#>



$startTime = Get-Date

#number of threads to run
$MaxThreads = 30

#Computers
$Computers = get-content (join-path $PSScriptRoot -ChildPath "\Collection Physical Workstations.txt")

if($Computers.Count -lt $MaxThreads){$MaxThreads = $Computers.Count}

$monitors = @()
$jobNumber = 0

$Command = {
        
    $PCName = $args[0]

    #test if we can ping the machine
    if(Test-Connection -ComputerName $PCName -count 2 -Quiet){
        #try statement catches the error where the PC does not have a monitor
        try{
            $Monitors = Get-WmiObject WmiMonitorID -Namespace root\wmi -ComputerName $pcname -ErrorAction stop

            $objects = @()

            #create an object for each monitor
            ForEach ($Monitor in $Monitors)
            {
	            $Manufacturer = ($Monitor.ManufacturerName -notmatch "^0"| ForEach{[char]$_}) -join ""
	            $Name = ($Monitor.UserFriendlyName -notmatch "^0"| ForEach{[char]$_}) -join ""
	            $Serial = ($Monitor.SerialNumberID -notmatch "^0"| ForEach{[char]$_}) -join ""

                $obj =New-Object psobject -Property @{
                Manufacturer = $Manufacturer
                Model = $Name
                SN = $Serial
                Computer = $PCName
                }
    
	            $objects += $obj
	        
            }
            return $objects
            }
        catch{
            $obj =New-Object psobject -Property @{
                Manufacturer = "No Monitors"
                Model = "No Monitors"
                SN = "No Monitors"
                Computer = $PCName
            }
        return $obj
        }
    }
    else{
        $obj =New-Object psobject -Property @{
            Manufacturer = "Can't ping"
            Model = "Can't ping"
            SN = "Can't ping"
            Computer = $PCName
        }
        return $obj
    }
}


#initialize first jobs
for($i = 0; $i -lt $MaxThreads; $i++){
    Start-Job -ArgumentList $Computers[$i] -Name $Computers[$i] -ScriptBlock $Command | Out-Null
    $jobNumber++
}

$completedJobs = 0
$Jobs = Get-Job
#continue to add more jobs as they complete
Write-Progress -Activity "getting monitors" -PercentComplete (0)
while($true){
    
    #check if all the PC's have been done
    if(($jobs.count -eq 0) -and ($jobNumber -gt $Computers.Count)) {break}
    #loop through current jobs and find completed ones to get the return values and start new jobs
    for($i = 0; $i -lt $jobs.count; $i++){
        if($jobs[$i].State -eq 'Completed'){
            $jobCompletion = Receive-Job $jobs[$i] -Wait -AutoRemoveJob
            if($jobCompletion -ne $null){
                $monitors += $jobCompletion
            }
            $CompletedJobs++
            Write-Progress -Activity "getting monitors"  -status ("$completedJobs/"+$computers.count) -PercentComplete (($completedJobs/$Computers.count)*100)
            $jobNumber++

            if($jobNumber -lt $Computers.Count){
                Start-Job -ArgumentList $Computers[$jobNumber] -Name $Computers[$jobNumber] -ScriptBlock $Command | Out-Null
            }
        }
    }
    $Jobs = Get-Job
    $Jobs | wait-job -any | Out-Null
}

Write-Progress -Activity "getting monitors" -Completed

write-host "All jobs done" -ForegroundColor Cyan


$monitorTable = @()

$monitors | foreach{
    if(!(($_.SN -eq "Can't ping") -or ($_.SN -eq "No Monitors"))){$MonitorTable += [string]$_.SN + "`t" + $_.computer}
}
    
$endTime = Get-Date
$time = ($endTime - $startTime).totalMinutes
$minutes = 0
while($time -ge 1){$time--;$minutes++}
$seconds = $time*60

$seconds = [math]::Round($seconds,2)

write-host "it took $minutes minutes and $seconds seconds to complete" -ForegroundColor Green


