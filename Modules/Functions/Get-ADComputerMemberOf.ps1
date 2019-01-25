Function Get-ADComputerMemberOf{
    [cmdletBinding()]
    Param(
        [Parameter(Mandatory = $False)]
        [object]$ComputerName = $ENV:ComputerName
    )
    Begin{

    }

    Process{
        Try{
            $MemberOf = (Get-AdComputer $ComputerName -Properties MemberOf).MemberOf
            $FormattedMembers = @()
            Foreach($Member in $MemberOf){
                $TempStr = $Member.split(",")[0].TrimStart("CN=")
                $FormattedMembers += $TempStr
            }
            $FormattedMembers = $FormattedMembers | Sort-Object
            Return $FormattedMembers
        }
        Catch{
            Write-Error -Message "Computer not found in Active Directory"
        }
    }

    End{
        
    }
}