<#

A function to count up the number of times a user has logged onto a system.



#>



$log = $logs[0]
$User = (New-Object System.Security.Principal.SecurityIdentifier $Log.ReplacementStrings[1]).Translate([System.Security.Principal.NTAccount])

$PCLogs = new-object -Property @{

}
([wmi] '').ConvertToDateTime("20140407035822.388000+000")

# gmwi -class win32_computersytem
