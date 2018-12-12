#function to get Laptop Mac Addresses remotely

Function Get-LaptopMacAddress{
    [cmdletBinding()]
    Param(
        [parameter()]
        [object]$ComputerName = $env:COMPUTERNAME
    )
    Begin{}
    Process{
        if(Test-Connection -ComputerName $ComputerName -Count 2 -Quiet){
            try{ $ComputerSystem = gwmi -Class Win32_ComputerSystem -ComputerName $ComputerName
                if($ComputerSystem.Model -eq "Latitude 5285"){
                    $Ipconfig = Invoke-Command -ComputerName $ComputerName -ScriptBlock { IPConfig /all}
                
                                    #find a txt file in the same directory
                    $textFile = (join-Path -path $PSscriptRoot -childpath MacAddresses.txt)
                    #if a txt file doesn't exist in the current directory, make one.

                    $assetTags = (Import-Clixml (Join-Path -Path $PSscriptRoot -ChildPath AssetTags.xml))


                    $foundWirelessLanAdapter = $false
                    $lineNumber = 0
                    Foreach($line in $ipconfig){
                        if($line -eq "Wireless Lan adapter Wi-Fi:"){ 
        
                            $WLANAddress = $ipConfig[$lineNumber + 5].TrimStart("   Physical Address. . . . . . . . . : ")
                            $foundWirelessLanAdapter = $true
                        }
                        elseif($line -eq "Ethernet adapter Ethernet:"){
        
                            $LANAddress = $ipConfig[$lineNumber + 4].TrimStart("   Physical Address. . . . . . . . . : ")
        
                        }
                        $lineNumber++
                    }
                    if($foundWirelessLanAdapter){
                        $assetTag = $assetTags | ? { $_.ComputerName -eq $ComputerName}
                        $assetTag = $assetTag.AssetTag
                        $AdDescription = (Get-ADComputer $ComputerName -Properties Description).Description
                        $ADdescription = $AdDescription.split(" ")[0]

                        $userName = (Get-ADUser -Filter {SamAccountName -eq $ADdescription} -Properties DisplayName).DisplayName
                        
                        if(!$userName){
                            $userName = "Vacant"
                        }
                        $LanAddress = $LANAddress.Replace("-",":")
                        $WLANAddress = $WLANAddress.Replace("-",":")
                        $str = "$WLanAddress`t$LanAddress`t$UserName`t$ComputerName`t$AssetTag"

                        Out-File -FilePath $textFile -Append -InputObject $str

                        write-host ("Wrote`n '$str'`n to $textFile.")
                    }
                    else{
                        Write-Warning "Couldn't find Wireless Lan adapter mac address"
                        return 0
                    }

                }
                else{
                    Write-Warning "PC is not a Latitude 5285"
                    return 0
                }
            }
            catch{
                Write-Warning "Error getting WMI object Win32_ComputerSystem"
                return 0
            }

        }
        else{
            Write-Warning "Could not ping PC $ComputerName"
            return 0
        }
    }
    End{}
}


