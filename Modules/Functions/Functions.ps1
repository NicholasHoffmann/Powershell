Function Get-UserLastLogonTime{

<#
.SYNOPSIS
Gets the last logon time of users on a Computer.

.DESCRIPTION
Pulls information from the wmi object Win32_UserProfile and outputs an array of objects with properties Name and LastUseTime.
If a date that is year 1 is outputted, then an error occured.

.PARAMETER ComputerName
[object] Specify which computer to target when finding logged on Users.
Default is the host computer

.PARAMETER User
[string] Specify a user to find on the computer.

.PARAMETER ListAllUsers
[switch] Specify the function to list all users that logged into the computer.

.PARAMETER GetLastUsers
[switch] Specify the function to get the last user to log onto the computer.

.PARAMETER ListCommonUsers
[switch] Specify to the function to list common user.

.INPUTS
You may pipe objects into the ComputerName parameter.

.OUTPUTS
outputs an object array with a size dependant on the number of users that logged in with propeties Name and LastUseTime.


#>

    [cmdletBinding()]
    param(
        #computer Name
        [parameter(Mandatory = $False, ValueFromPipeline = $True)]
        [object]$ComputerName = $env:COMPUTERNAME,

        #parameter set, can only choose one from this group
        [parameter(Mandatory = $False, parameterSetName = 'user')]
        [string] $User,
        [parameter(ParameterSetName = 'all users')]
        [switch] $ListAllUsers,
        [parameter(ParameterSetName = 'Last user')]
        [switch] $GetLastUser,

        #Whether or not you want the function to list Common users
        [switch] $ListCommonUsers
    )

    #Begin Pipeline
    Begin{
        #List of users that are present on all PCs, these won't output unless specified to do so.
        $CommonUsers = ("NetworkService", "LocalService", "systemprofile")
    }
    
    #Process Pipeline
    Process{
        #ping the machine before trying to do anything
        if(Test-Connection $ComputerName -Count 2 -Quiet){
            #try to get the OS version of the computer
            try{$OS = (gwmi  -ComputerName $ComputerName -Class Win32_OperatingSystem -ErrorAction stop).caption}
            catch{
                #had an error getting the WMI-object
                return New-Object psobject -Property @{
                            User = "Error getting WMIObject Win32_OperatingSystem"
                            LastUseTime = get-date 0
                            }
              }
            #make sure the OS retrieved is either Windows 7 or Windows 10 as this function has not been set to work on other operating systems
            if($OS.contains("Windows 10") -or $OS.Contains("Windows 7")){
                try{
                    #try to get the WMiObject win32_UserProfile
                    $UserObjects = Get-WmiObject -ComputerName $ComputerName -Class Win32_userProfile -Property LocalPath,LastUseTime -ErrorAction Stop
                    $users = @()
                    #loop that handles all the data that came back from the WMI objects
                    forEach($UserObject in $UserObjects){
                        #extract the username from the local path, first find where the last slash is after, get everything after that into its own string
                        $tempUserString = $UserObject.localPath.Split("\")[$UserObject.localPath.Split("\").length -1 ]
                        #if list common users is turned on, skip this block
                        if(!$listCommonUsers){
                            #check if the user extracted from the local path is a common user
                            $isCommonUser = $false
                            forEach($userName in $CommonUsers){ 
                                if($userName -eq $tempUserString){
                                    $isCommonUser = $true
                                    break
                                }
                            }
                        }
                        #if the user is one of the users specified in the common users, skip it unless otherwise specified
                        if($isCommonUser){continue}
                        #check to see if the user has a timestamp for there last logon 
                        if($UserObject.LastUseTime -ne $null){
                            #This converts the string timestamp to a DateTime object
                            $TempUserLastUseTime = ([WMI] '').ConvertToDateTime($userObject.LastUseTime)
                        }
                        #the user had a local path but no timestamp was found for last logon
                        else{$TempUserLastUseTime = Get-Date 0}
                        #add user to array
                        $users += New-Object -TypeName psobject -Property @{
                            User = $tempUserString
                            LastUseTime = $TempUserLastUseTime
                            }
                    }
                }
                catch{
                    #error trying to retrieve WMI obeject win32_userProfile
                    return New-Object psobject -Property @{
                        User = "Error getting WMIObject Win32_userProfile"
                        LastUseTime = get-date 0
                        }
                }
            }
            else{
                #OS version was not compatible
                return New-Object psobject -Property @{
                    User = "Operating system $OS is not compatible with this function."
                    LastUseTime = get-date 0
                    }
            }
        }
        else{
            #Computer was not pingable
            return New-Object psobject -Property @{
                User = "Can't Ping"
                LastUseTime = get-date 0
                }
        }

        #check to see if any users came out of the main function
        if($users.count -eq 0){
            $users += New-Object -TypeName psobject -Property @{
                User = "NoLoggedOnUsers"
                LastUseTime = get-date 0
            }
        }
        #sort the user array by the last time they logged in
        else{$users = $users | Sort-Object -Property LastUseTime -Descending}
        #main output block
        #if List all users was chosen, output the full list of users found
        if($ListAllUsers){return $users}
        #if get last user was chosen, output the last user to log on the computer
        elseif($GetLastUser){return ($users[0])}
        else{
            #see if the user specified ever logged on
            ForEach($Username in $users){
                if($Username.User -eq $user) {return ($Username)}            
            }

            #user did not log on
            return New-Object psobject -Property @{
                User = "$user"
                LastUseTime = get-date 0
                }
        }
    }
    #End Pipeline
    End{Write-Verbose "Function get-UserLastLogonTime is complete"}
}