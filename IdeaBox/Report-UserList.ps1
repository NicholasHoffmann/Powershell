
#function is dependent on get-standardADAccounts
Function Report-UserList{
    [cmdletBinding()]
    Param(
        [Parameter(Mandatory = $True)]
        $Path = 'C:\Reports\UserList.CSV'
    )

    #Specify which properties to get out of AD and the order to do it in
    $ADProperties  = 'Title', 'EmailAddress', 'DisplayName', 'Department', 'Office', 'Manager', 'SamAccountName', 'Name'
    
    #Get the standard users
    $Users = Get-StandardADAccounts -ADProperties $ADProperties

    #Convert the Manager property to something actually meaningful
    $Users | %{$Temp = $_.Manager;
        if(!$Temp){$Temp = 'No Manager'}
        $_.Manager = (Get-ADUser -Filter {DistinguishedName -eq $Temp} -Properties DisplayName -EA Ignore).DisplayName}
    
    #Export it to a CSV
    $Users | Select $ADProperties | export-CSV -Path $Path -NoTypeInformation -Encoding UTF8
    
    
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


Report-UserList -Path C:\Reports\UserList.csv