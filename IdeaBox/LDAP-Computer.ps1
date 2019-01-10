#original code from Mdedeboer
Function LDAP-Computer{
    [cmdletBinding()]
    Param(
        [Parameter()]
        [String]$ComputerName = $env:COMPUTERNAME
    )

    Do{
        $SysInfo = New-Object -ComObject "ADSystemInfo"
        $type = $SysInfo.GetType()
        $compDN = $type.InvokeMember('ComputerName','GetProperty',$null,$SysInfo,$null)

        $compadsi = [adsi] "LDAP://$CompDN"
        start-sleep 5
        $i++
    }While((!($compADSI)) -and $i -lt 5)
}