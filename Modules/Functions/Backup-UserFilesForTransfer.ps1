    Function Backup-UserFilesForTransfer{
        [cmdletBinding()]
        Param(
            [Parameter(Mandatory = $True)]
            [string]$ComputerName,

            [Parameter(Mandatory = $False)]
            [string]$UserName
        )
        $ComputerName = $ComputerName.ToUpper()
        if(Test-Connection -ComputerName $ComputerName -Quiet){
            $HomePath = "C:\userProfileData"
            if(!(Test-Path -Path $HomePath)){
                New-Item -Path $HomePath -ItemType Directory
            }
            $UserPath = Join-Path -Path "C:\Users" -ChildPath $Username

            $Namespace = "Root\CimV2"
            $Properties = "LocalPath"
            $Selection = $Properties.Split(",")
            $Query = "Select $Properties from Win32_UserProfile where RoamingConfigured = True"
            $Users = Get-WmiObject -Namespace $NameSpace -Query $Query -ComputerName $ComputerName | Select-Object $Selection
            
            if($UserName){
                $Users = $Users | Where-Object {$_.LocalPath -eq $UserPath}
            }

            
            $Users | Add-Member -NotePropertyName 'NetworkPath' -NotePropertyValue 0
            $Length = $Users.length
            if(!$Length){$Length = 1}
            for($i = 0; $i -lt $Length; $i++){
                $Path = Join-Path -Path "\\$ComputerName\C$\Users" -ChildPath ($Users[$i].LocalPath.Split("\")[2])
                $Users[$i].NetworkPath = $Path
            }
         
        
            $FilesToCopy = "AppData\Local\Google\Chrome\User Data\Default\Bookmarks
            AppData\Roaming\Microsoft\Signatures".Split("`n").trim()

            
            Foreach($ChildPath in $FilesToCopy){
                Foreach($user in $Users){
                    $CurrentPath = Join-Path -Path $User.NetworkPath -ChildPath $ChildPath
                    $CurrentCopyPath = Join-Path -Path $HomePath -ChildPath ($user.LocalPath.split("\")[2])
                    
                    $Temp = Split-Path $CurrentPath -Leaf
                    $CurrentCopyPath = Join-Path -Path ([string]$CurrentCopyPath + "-$ComputerName") -ChildPath $Temp

                    if(!(Test-Path -Path $CurrentCopyPath)){
                        New-Item -Path $CurrentCopyPath -ItemType Directory
                    }

                    if(Test-path $CurrentPath){
                        Get-ChildItem -Path $CurrentPath -Force | Copy-Item -Destination $CurrentCopyPath -Force -Recurse
                    }
                    Else{
                        Write-Host ([string]$CurrentPath + " does not exist")
                    }
                }
            }
        }
        Else{
            Write-Error -Message "Unable to ping computer"
            Return 1
        }
        
}

