######
# Get printer data and manipulate it for Fun reports
#
#
#
#
######

<#
$Printers = get-printer -ComputerName Nacon
 foreach($Printer in $Printers){
    $Successful = $False
    if(Test-Connection -ComputerName $printer.name -Quiet){
        $Successful = $true

    }
    write-host ($printer.name + "`t" + $Successful)
 }
 #>
 $PSScriptRoot
