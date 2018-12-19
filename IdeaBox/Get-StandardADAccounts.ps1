
#This function will get all the AD users that are useful we can pass a CSV of the properties that we want.

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


$ADProperties = $args[0]
if(!$ADProperties){
    $ADProperties = 'Enabled'
}
Return Get-StandardADAccounts $ADProperties
