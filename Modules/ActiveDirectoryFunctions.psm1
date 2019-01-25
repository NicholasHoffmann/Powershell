

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

Function Get-StandardADAccounts{
    [cmdletBinding()]
    
    Param(
        [Parameter(Mandatory = $False)]
        $ADProperties
    )
    
    Write-Verbose "Properties defined are $ADProperties"
    #The filters are as followed
    #A regular user has an employeeID
    #A contractor does not have an employeeID so we will use Title has the word contractor
    #The User is not disabled (deactivated)
    $ADUsers = Get-ADUser -Filter {((EmployeeID -ne 0) -or (Title -like "*Contractor*")) -and (Enabled -eq $True)} -Properties $ADProperties
    
    Return $ADusers
    
    }

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