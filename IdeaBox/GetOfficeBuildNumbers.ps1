$win7group = (Get-ADGroup 'SCCM_SWDist_Comp_MSProjectOnlineClient').distinguishedname 
$win10group = (Get-ADGroup 'SCCM_SWDist_Comp_MSOffice2016withProject').distinguishedname

$computers = @()
Get-ADComputer -Filter * -Properties OperatingSystem, MemberOf | Where-Object {$_.MemberOf -contains $win7Group -or $_.MemberOf -contains $win10group} | Foreach {$computers += $_}
$computersData = @()
foreach($comp in $computers){
    $computerName = $comp.Name
    $DisplayName = ''
    $DisplayVersion = ''
    $Publisher = ''
    $ComputerError = 0

    if(test-connection -Quiet -ComputerName $comp.Name){
        Invoke-Command -ComputerName $comp.Name -ScriptBlock {
        Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\ProjectProRetail* |
        Select-Object DisplayName, DisplayVersion, Publisher } | %{$DisplayName = $_.DisplayName; $DisplayVersion = $_.DisplayVersion; $Publisher = $_.Publisher}
    }
    Else{$ComputerError = '1'}
    $ComputersData += new-object psobject -Property @{ComputerName  = $computerName
    DisplayName = $DisplayName
    DisplayVersion = $DisplayVersion
    Publisher = $Publisher
    Error = $ComputerError
    OperatingSystem = $comp.OperatingSystem
    }
}
