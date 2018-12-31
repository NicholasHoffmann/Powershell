<#

This script will go along Certify-Inventory. It's only purpose is to provide test information so I don't have to query AD and WMI.
Certify-Inventory will probably be object focused to simplify testing the data.


So this will simply create a powershell cli-XML that Certify-Inventory can use.


#>

$ComputerProperties = New-Object -TypeName PSObject -Property @{
    #Basic Properties
    ComputerName = 'Undefined'
    OperatingSystem = 'Undefined'
    IPAddress = 'Undefined'
    Model = 'Undefined'


    #Active Directory Properties
    ADComputer = New-Object -TypeName PSObject -Property @{
        Description = 'Undefined'
        MemberOf = 'Undefined'
    }


    #Active Directory User Properties
    ADUser = New-Object -TypeName PSObject -Property @{
        #Whether an user was actually found to that matched the computers AD description
        Found = $False
        Location = 'Undefined'
        Department = 'Undfined'

    }
    

    #Snow Properties
    Snow = New-Object -TypeName PSObject -Property @{
        Location = 'Undefined'
        UserName = 'Undefined'
        UserID = 'Undefined'
        Department = 'Undefined'
    }
    

    #How Many Monitors there is on a PC is unknown so we will leave it as an empty object
    Monitors = @()
}