<#

The purpose of this program is too compare the information found in Active Directory to snow

This will be accomplished by pulling information about a computer from Active Directory,
It will attempt to find a user in the description of that PC.
If a user is succesfully found, we will pull information about that user aswell.





#>



#we only want to build the macthing machine once, we will use a command like Get-AdUser -Filter {DisplayName -ne $null}
#to get all the users in a nicely built macthing machine
#Builds the string MatchingMachine




Function Get-ComputerProperties{

    [cmdletbinding()]
    param(
        [parameter(Mandatory = $true)]
        [object[]] $ComputerNames,
        [string[]] $users
        
    )


    Function Build-MacthingMachine{

        [cmdletBinding()]
        param(
            [Parameter(Mandatory = $true)]
            [string[]]$InputStrings,

            [parameter(Mandatory = $false)]
            [int]$MaxStates = 500,

            [parameter(Mandatory = $false)]
            [int]$MaxCharacters = 93

        )


        #Initialize functions Output, Failure, and Goto
        [int[]]$out = @(0)*$MaxStates
        [int[][]]$goto = ,(@(-1)*$MaxCharacters)*$MaxStates
        [int[]]$Failure = @(-1)*$MaxStates

        [int]$states = 1

        
        for($i = 0; $i -lt [int]($InputStrings.Count); $i++){
            $word = $InputStrings[$i]
            
            [int] $currentState = 0

            for($h = 0; $h -lt $word.Length; $h++){
                [int] $char = [int]([char]$word[$h] - [char]'a')
                

                if($goto[$currentState][$char] -eq -1){$goto[$currentState][$char] = $states++}

                $currentState = $goto[$currentState][$char]
            }

            $out[$currentState]  = ($out[$currentState] -bor (1 -shl $i))

        }


        for($ch = 0; $ch -le $MaxCharacters; ++$ch){
            if($goto[0][$ch] -eq -1){
                $goto[0][$ch] = 0
            }
        }

        $queue =  [System.Collections.Queue]::Synchronized((New-Object System.Collections.Queue))

        for($ch = 0; $ch -lt $MaxCharacters; $ch++){
            if($goto[0][$ch] -ne 0){
                $Failure[$goto[0][$ch]] = 0
                $queue.Enqueue($goto[0][$ch])
            }
        }

        while($queue.Count){
            [int]$state = $queue.Dequeue()

            for($ch = 0; $ch -lt $MaxCharacters; ++$ch){
                if($goto[$state][$ch] -ne -1){
                    $FailureValue = $Failure[$state]
                    while($goto[$FailureValue][$ch] -eq -1){
                        $FailureValue = $Failure[$FailureValue]
                    }

                    $FailureValue = $goto[$FailureValue][$ch]
                    $Failure[$goto[$state][$ch]] = $FailureValue

                    $out[$goto[$state][$ch]] = $out[$goto[$state][$ch]] -bor $out[$FailureValue];
                    $queue.Enqueue($goto[$state][$ch])
                }
            }
        }


        return @($out,$goto,$Failure)

    }

    Function Search-Words{

        [cmdletBinding()]
        param(
            [parameter(Mandatory = $True)]
            [string[]]$StringArray,

            [parameter(Mandatory = $True)]
            [string]$String,

            [switch]$EqualizeTextToStandardChars,

            [parameter(Mandatory = $False)]
            [int]$MaxStates = 500,

            [parameter(Mandatory = $False)]
            [int]$MaxCharacters = 93

        )

    
    
        #Returns the next state the machine will transition to using goto
        #and failure functions.
        #currentState - The current state of the machine. Must be between
        #                0 and the number of states - 1, inclusive.
        #nextInput - The next character that enters into the machine.
        Function Find-NextState{

            [cmdletBinding()]
            param(
                [parameter(Mandatory = $true)]
                [int] $currentState,

                [parameter(Mandatory = $true)]
                [char] $nextInput

            )

            [int]$answer = $currentState
            [int]$ch = [int]($nextInput - [char]'a')


            while($goto[$answer][$ch] -eq -1){
                $answer = $Failure[$answer]
            }

            return $goto[$answer][$ch]

        }

    
        if($EqualizeTextToStandardChars){
            for($i = 0; $i -lt $StringArray.Count; $i++){
                $StringArray[$i] = $StringArray[$i].ToLower()
            }
            $string =$string.ToLower()
        }

        <#
        $out = $args[0]
        $goto = $args[1]
        $Failure = $args[2]
        #>
    
        $Output = @()
        $CurrentState = 0

        for($i = 0; $i -lt $string.Length; $i++){
            $CurrentState = (Find-NextState -currentState $CurrentState -nextInput $String[$i])
            if($out[$CurrentState] -eq 0){continue}

            for($h = 0; $h -lt $stringArray.Count; $h++){

                if ($Out[$CurrentState] -band (1 -shl $h)){ 
                
                    $Output += New-Object psobject -Property @{
                        String = [string]$StringArray[$h]
                        StartIndex = [int]($i - $StringArray[$h].Length +1)
                        EndIndex = [int]$i
                    }

                } 
            }
        }

        return $Outputs
    }

    $Users = get-aduser -Filter * -Properties employeeID,title | Where-Object {($_.employeeID -ne $null) -or ($_.title -like "*contractor*")} | select-object samaccountname |sort-object SamAccountName
    
    $args = Build-MacthingMachine -InputStrings $users -MaxStates 2000 -MaxCharacters 93
    $out = $args[0]
    $goto = $args[1]
    $Failure = $args[2]
    

    $Computers = @()
    #output object Array constructer
    for($i = 0; $i -lt $ComputerNames.Count; $i++){
            $Computers += New-Object psobject -Property @{
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
    }


    
    $count = 0
    Write-Progress -Activity "Collecting Information" -Status ("$Count/" + $ComputerNames.Count) -PercentComplete (($Count/$ComputerNames.count)*100)

    forEach($Computer in $Computers){
        $count++
        Write-Progress -Activity "Collecting Information" -Status ("$Count/" + $ComputerNames.Count) -PercentComplete (($Count/$ComputerNames.count)*100)

        #see if the computer exists in Active Directory
        try{ 
            $ADcomputer = get-ADComputer $Computer.Name -Properties Description, OperatingSystem -ea stop
            $Computer.Exists = $True
            $Computer.Description = $ADcomputer.Description
            $Computer.OperatingSystem = $ADcomputer.OperatingSystem
            if(Test-Connection -ComputerName $Computer.Name -Count 2 -Quiet){
                $Computer.IPAddress = (Test-Connection -ComputerName $Computer.Name -Count 1).IPV4Address.IPAddressToString
                $Computer.IPFloor = $FloorDictionary.($Computer.IPAddress.split(".")[2])
                #get the last logged on users here
                $Computer.LastLogons = Get-UserLastLogon -ComputerName $Computer.Name
                #get the attached monitors here
                
            }
            #now attempt to find the user
            
            $SplitValue = ""
            $Attempts = 0
            $userNameFound = $False
            while(!$UserNameFound){
                switch($Attempts){
                    0{$SplitValue = ""}
                    1{$SplitValue = " "}
                    2{$SplitValue = "_"}
                    3{$SplitValue = "-"}
                    4{break}
                }
                
                $TempUserString = $Computer.Description.split($SplitValue)[0]
                try{
                    $ADuser = get-ADUser $TempUserString -properties * -ea stop
                    $userNameFound = $True
                    break
                    
                }
                #try to split it again
                catch{$Attempts++}
            }
            if(!$userNameFound){
                #Stronger method to find the username will be employed if one was not found with the basic one
                $TempUserString = Search-Words -StringArray $Users -String $Computer.Description -EqualizeTextToStandardChars
                if($TempUserString -ne $null){
                    #test if this user is in AD (just a double check should be fine nonetheless
                    try{
                        $ADUser = Get-ADUser $TempUserString -Properties * -ea stop
                        $userNameFound = $true
                    }
                    #User does not exist within Active Directory
                    catch{}
                    
                }
            }
            
            if(!$userNameFound){
                $Computer.User.Exists = $True
                $Computer.User.Name = $ADuser.SamAccountName
                $Computer.User.Enabled = $ADUser.Enabled
                $Computer.User.Location = $ADuser.Location
                $Computer.User.Department = $ADuser.Department
                $Computer.User.LastLogon = Get-userLastLogon -ComputerName $Computer.Name -User $Computer.User

                
            }
            else{}

            


        }
        #the computer does not exist within Active Directory
        catch{}
    }


    return $Computers
    
}

$test = Get-ComputerProperties -ComputerNames "vdi-0895" 

#import the snow portion of the data to the object array of computers



#now that all the information is nicely stowed away we may start manipulating and checking if all the data matches to eachother and makes sense.





