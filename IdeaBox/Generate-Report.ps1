<#
Takes a Clixml and generates a CSV

#>

$Import = (Get-ChildItem -path $PSScriptRoot -Recurse -Include *.xml)[0]
$Export = join-path -Path $PSScriptRoot -ChildPath '7270Report.txt'
if($Import){
    $objects = Import-Clixml $Import
    if(Test-Path -Path $Export){
        Remove-Item -Path $Export
    }

    Out-File -FilePath $Export -Append -InputObject "ComputerName`tAssignedUserID`tAssignedUserName`tAssignedDepartment`tPinged`tLastAttempt`tIMEI`tScanIMEI`tSimCard`tScanSIMCard`tPhoneNumber`tScanPhoneNumber`tLastScanned"
    foreach($object in $objects){
        
        Out-File -FilePath $Export -Append -InputObject ([string]$object.Computername + "`t" + $object.AssignedUserID + "`t" + $object.AssignedUserName + "`t" + $object.AssignedDepartment + "`t" + $object.Pinged + "`t" + $object.LastAttempt + "`t" + $object.IMEI + "`t" + $object.ScanIMEI + "`t" + $object.SimCard + "`t" + $object.ScanSIMCard + "`t" + $object.PhoneNumber + "`t" + $object.ScanPhoneNumber + "`t" + $object.LastScanned)
    }
}
Else{Write-Warning "XML not found"}