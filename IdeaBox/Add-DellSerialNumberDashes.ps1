Function Add-DellSerialNumberDashes{

[cmdletBinding()]
Param(
    [parameter(Mandatory = $True)]
    [string]$SerialNumber
)
if($SerialNumber.Length -eq 20){
    $Str = ""
    $DashCount = 1
    $AddDash = 2
    Switch($DashCount){
    1{$addDash = 2}
    2{$addDash = 7}
    3{$addDash = 12}
    4{$addDash = 15}
    }

    for($i = 0; $i -lt 20; $i++){
        Switch($DashCount){
            1{$addDash = 2}
            2{$addDash = 8}
            3{$addDash = 13}
            4{$addDash = 16}
        }
        if($addDash -eq $i){
            $Str += "-"
            $Str += $SerialNumber[$i]
            $Dashcount++
        }
        Else{
            $Str += $SerialNumber[$i]
        }
    }

    Return $Str

}
Else{
    Write-Warning "$SerialNumber is not 20 digits"
    Return 1
}

}