Function Measure-OutlookArchive{
    [cmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline = $True)]
        [object]$ComputerName = $ENV:COMPUTERNAME    
    )
    Begin{}
    Process{
        $Result = 0
        if(Test-Connection -ComputerName $ComputerName -Count 2 -Quiet){
            Try{    
                $Properties = "LocalPath,SID"
                $Selection = $Properties.Split(",")
                $Query = "Select $Properties from Win32_UserProfile" 
                $Users = Get-WmiObject -Query $Query -ComputerName $ComputerName | Where-Object {$_.SID.Length -gt 40} | Select-Object $Selection -ExcludeProperty SID
                for($i = 0; $i -lt $Users.Length; $i++){
                    $Users[$i].LocalPath = $Users[$i].LocalPath.Split("\")[2]
                }
                $Users | Add-Member -NotePropertyName 'PstSize' -NotePropertyValue 0
                $Users | Add-Member -NotePropertyName 'ComputerName' -NotePropertyValue $ComputerName
                if(Test-path -Path \\$ComputerName\c$){
                    foreach($User in $Users){
                        $UserPath = $User.LocalPath
                        $Path = "\\$ComputerName\C$\Users\$UserPath\Appdata\Local\Microsoft\Outlook"
                        if(Test-Path -Path $path){
                            $Size = (Get-ChildItem -Path $Path -Recurse -Include "*.pst"| Measure-Object -Sum Length).Sum
                            $User.PstSize = $Size
                        }
                    }
                }
                Else{
                    $Result = 4
                }
                $Users = $Users | Where-Object {$_.PstSize -gt 0}
            }
            Catch{
                $Result = 3
            }
        }
        Else{
            Write-Host "was not able to ping $computerName"
            $Result = 1
        }
        Write-Verbose "Error code $Result"
        Return $Users
    }
    End{
        
    }
}
