<#
The purpose of this script will be to validate the data we have inside our inventory software

To start we are going to use CSV exports from this inventory software, later on, since it is sql based. we may be able to integrate sql query to get the data quickly and efficiently.

Also, this will not be setup to automatically update inventory, instead it will provide a report of the errors found. Then someone will then be tasked to fix

Once the rules set in place have had enough time to prove themselves and the sql portion has been fully integrated. We can go even further and automatically change it.






#>

<#

Integrated rules,


The assigned user to a computer in Active Directory must be the same as the one in snow.
The assinged users Location must match the location assigned to this PC.
The Monitors attached to this PC must have the monitors assigned to the user.
The Monitors attached to this PC must have the same location.
The PCs Department must be the same as the Users Department.
The Location of these monitors must also be the same as the computer.
The Logon Logs of this computer should be the assigned user, of course there can be exceptions of this.



Extra checks we can do while we are doing this
The clients home in the OU structure must be the same as the PC. (Under workstations instead of clients of course)
The IP address can be used to verify the PC is on the correct floor, these can give a small check on shared PCs. We should track the last few IP addresses to get some statistics between floor hops.



We would need a database fr this to viable.
I would like to keep track of the location changes being applied to objects and PCs and the user making these changes to have an accurate auditing trail.



#>


<#
Sources of information
Monitor serial numbers can be obtained from
Gwmi -namespace Root\Wmi -class WmiMonitorID

To compare this against the ones in snow, we will have to trim down the ones in snow to follow PartNumber-ManufacturerDate-UniqueID
Of course at first it will find alot of the misentered Serial numbers in snow.

Ipconfig /all can get IP information

Most PCs Description use USERID - Description


This will be used to extract the Assigned User from Active Directory




#>