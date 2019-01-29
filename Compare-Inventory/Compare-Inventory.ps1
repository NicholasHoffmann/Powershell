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
Since Installing software is query based off of AD Members, we can validate what PC's should have 16GB of RAm


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



Function Compare-Inventory{
    #Main Function
    $EmptyPropertyValue = $null
    $MainProperties = @{
        #Basic Computer Properties
        Computer = @{
            Name = 0
            IPAddress = $EmptyPropertyValue
        }

        #WMI Logon information
        UserProfile = @()

        #Snow Properties
        Snow = @{
            UserID = $EmptyPropertyValue
            UserName = $EmptyPropertyValue
            Location = $EmptyPropertyValue
            Department = $EmptyPropertyValue
            Exists = $false
        }

        #ActiveDirectory
        AD = @{
            OperatingSystem = $EmptyPropertyValue
            Description = $EmptyPropertyValue
            OU = $EmptyPropertyValue
            MemberOF = $EmptyPropertyValue
            Exists = $false
        }

        #WMI Monitor Instances
        Monitors = @()

        $ADUser = @{
            Exists = $false

        }
    }

}

New-Object psobject -Property @{
    computer = (New-Object psobject -Property @{
        Name = $ComputerNames[$i]
        Exists = $false
        OperatingSystem = "n/a"
        Description = "n/a"
        IPFloor = "n/a"
        IPAddress = "n/a"
    
        LastLogons = @()

        snow = (New-Object psObject -Property @{
            UserID = "n/a"
            UserName = "n/a"
            Location = "n/a"
            Department = "n/a"
            exists = $False
        })
    
        Monitor1 = (New-Object psObject -Property @{
            SN = "n/a"
            Manufacturer = "n/a"
            Model = "n/a"
            exists = $false
            ErrorReason = "n/a"
            snow = (New-Object psObject -Property @{
                User = "n/a"
                Location = "n/a"
                AssetStatus = "n/a"
                })
            })

        Monitor2 = (New-Object psObject -Property @{
            SN = "n/a"
            Manufacturer = "n/a"
            Model = "n/a"
            exists = $false
            ErrorReason = "n/a"
            snow = (New-Object psObject -Property @{
                User = "n/a"
                Location = "n/a"

                AssetStatus = "n/a"
                })
            })
   
        Monitor3 = (New-Object psObject -Property @{
            SN = "n/a"
            Manufacturer = "n/a"
            Model = "n/a"
            exists = $false
            ErrorReason = "n/a"
            snow = (New-Object psObject -Property @{
                User = "n/a"
                Location = "n/a"
                AssetStatus = "n/a"
                })
            })
        #Close Computer Object
        })

    User = (New-Object psobject -Property @{
        Name = "n/a"
        Enabled = "n/a"
        Location = "n/a"
        Title = "n/a"
        Exists = $false
        LastLogon = Get-Date 0
    
        #Close User Object
        })
    index = $i

#Close Object Array
}

Function Find-FloorByIPAddress {
    [cmdletBinding()]
    Param(
        [Parameter(Mandatory = $True)]
        $IPAddress
    )

    #this function incorprates a simple switch case to determine what floor a PC it is on
    #The numbers we are looking for is the one in XXXs 10.1.XXX.198
    $Number = $IPAddress.Split[2]
    $Floor = switch($Number){
        201{'BCP1'}
        202{'BCP2'}
        203{'BCP3'}
        204{'BCP4'}
        205{'BCP5'}
        206{'BCP6'}
        207{'BCP7'}
        208{'BCP8'}
        209{'BCP9'}    

        211{'BCB1'}
        212{'BCB2'}
        213{'BCB3'}
        214{'BCB4'}
        215{'BCB5'}
        216{'BCB6'}

        240{'Wireless'}


    }

}


