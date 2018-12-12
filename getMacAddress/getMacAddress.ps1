<#
    gets the Wireless Lan adapter Wi-Fi Mac address
    
    Written by Nicholas Hoffmann
#>

cd $PSscriptRoot
#find a txt file in the same directory
$textFile = (Get-ChildItem -Filter MacAddresses.txt).FullName
#if a txt file doesn't exist in the current directory, make one.
if($textFile -eq $null){ 
    $textFile = Join-Path -Path $PSscriptRoot -ChildPath \MacAddresses.txt
    Out-File -FilePath $textFile -Append -InputObject "PCName`tMacAddress"
}

$ipConfig = ipconfig /all
if($ipConfig[18] -eq "Wireless Lan adapter Wi-Fi:"){
    $MacAddress = $ipConfig[23].TrimStart("   Physical Address. . . . . . . . . : ")
    $str = ([string]$env:ComputerName + "`t" + [string]$MacAddress)

    Out-File -FilePath $textFile -Append -InputObject $str 

    Read-Host ("Wrote '$str' to $textFile. (Press Enter to close)")

}
else{Write-Warning "Couldn't find Wireless Lan adapter mac address"; Read-Host "Press Enter to continue"}