Function TestIf-Directory{
[cmdletBinding()]
Param(
    [Parameter(Mandatory = $True)]
    [string]$ComputerName = $env:COMPUTERNAME,
    [string]$Path
      
)


$Test = 0


#Test = 0 Connection to the computer failed
#Test = 1 File specified is a directory
#Test = 2 File specified is a File
#Test = 3 File Path does not exist



if(Test-Connection -ComputerName $ComputerName -Count 2 -Quiet){
    if(Test-Path -Path $Path){
        $TempLeaf = split-path $Path -Leaf
        $TempParent = Split-Path $Path -Parent
        if(Get-ChildItem -Path $TempParent -Filter $TempLeaf | %{$_.PSIsContainer}){
            #It is a directory
            $Test = 1 
        }
        Else{
            #it is a file
            $Test = 2
        }
    }
    Else{
        #Path does not exist
        $test = 3
    }
}
Else{
    #was unable to ping the machine
    $test = 0
}

$obj = New-Object PSObject -Property @{
    ComputerName = $ComputerName
    Test = $Test
}
Write-Verbose ("Completed $Computername with result $test")
return $obj

}



$Results = @()
$Computers = Get-Content $PSScriptRoot\computers.txt
foreach($computer in $computers){
    $Path = "\\$Computer\c$\Program Files (x86)\Cisco Finesse"
    $Results += TestIf-Directory -ComputerName $computer -Path $Path -Verbose
}