<#

This function will retrieve the description of an AD computer then attempt to get an AD user out of that.

With this user we can get the distnguished name which will correlate to the proper distinguished name of the computer

When I get the Aho Corasick Algorighthm working I will get that included in here


#>


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




$ScriptPath = (Join-Path -Path $PSScriptRoot -ChildPath Get-StandardADAccounts.ps1) 
$arguments = 'Office, Title'

$Users = Invoke-Expression "$ScriptPath $arguments"
$Users = $Users | Sort-Object SamAccountName





$Computers = Get-ADComputer -Filter {OperatingSystem -like "*Windows 7*"} -Properties Description | ? {$_.Name -notlike "*VDI-*"} | ?{$_.DistinguishedName -notlike "*OU=Workstations*"}
$Output = @()
Foreach($computer in $Computers){
    $Description = $computer.Description
    if(!($Description)){$Description = 0}
    $Aduser = 0
    $ADuser = get-aduser -Filter {SamAccountName -eq $Description} -EA Ignore
    if($Aduser){
        $firstComma = $Computer.DistinguishedName.indexOf(",") + 1
        $ComputerDistinguishedName = $Computer.DistinguishedName.Substring($firstComma)

        $firstComma = $Aduser.DistinguishedName.IndexOf(",") + 1

        $SecondComma = $Aduser.DistinguishedName.subString($firstComma).IndexOf(",") + 1 + $firstComma
        $ADUserDistinguishedName = $Aduser.DistinguishedName.subString($SecondComma)

        if($ComputerDistinguishedName -eq $ADUserDistinguishedName){
            
            $Result = 'Okay'
        }
        Else{
            
            $Result = 'Not Okay'
        }

    }
    Else{
        
        $Result = 'Skipped'
    }

    $Output += new-object PSobject -Property @{ComputerName = $computer.Name
    Result = $Result
    Computerfolder = $ComputerDistinguishedName
    UserFolder = $ADUserDistinguishedName}

}

$Total = ($Output | ? {$_.Result -ne 'Skipped'}).Count
$Okay = ($Output | ? {$_.Result -ne 'Okay'}).Count
$NotOkay = ($Output | ? {$_.Result -ne 'Not Okay'}).Count

write-host (($Okay/$Total)*100)




