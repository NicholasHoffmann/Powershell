<#


This is a test script



1234

#>

[int[]]$out = @(0)*500
[int[][]]$g = ,(@(-1)*26)*500
[int[]]$f = @(-1)*500

[int]$states = 1


Function Build-MacthingMachine{

    [cmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$InputStrings,

        [parameter(Mandatory = $false)]
        [int]$MaxStates = 500,

        [parameter(Mandatory = $false)]
        [int]$MaxCharacters = 26

    )

    Begin{
        $out = $Global:out
        $g = $Global:g
        $f = $Global:f
        $states = 1
    }


    Process{
        
        for($i = 0; $i -lt [int]($InputStrings.Count); $i++){
            $word = $InputStrings[$i]
            
            [int] $currentState = 0

            for($h = 0; $h -lt $word.Length; $h++){
                [int] $char = [int]([char]$word[$h] - [char]'a')
                

                if($g[$currentState][$char] -eq -1){$g[$currentState][$char] = $states++}
                #Write-Verbose ("" + $g[$currentState][$char])
                $currentState = $g[$currentState][$char]
            }

            $out[$currentState]  = ($out[$currentState] -bor (1 -shl $i))
            #Write-Verbose ("" + $out[$currentState] -bor (1 -shl $i))
        }


        for($ch = 0; $ch -le $MaxCharacters; ++$ch){
            if($g[0][$ch] -eq -1){
                $g[0][$ch] = 0
            }
        }

        $queue =  [System.Collections.Queue]::Synchronized((New-Object System.Collections.Queue))

        for($ch = 0; $ch -lt $MaxCharacters; $ch++){
            if($g[0][$ch] -ne 0){
                $f[$g[0][$ch]] = 0
                $queue.Enqueue($g[0][$ch])
            }
        }

        while($queue.Count){
            [int]$state = $queue.Dequeue()
            #Write-Verbose ("" + $state)
            for($ch = 0; $ch -lt $MaxCharacters; ++$ch){
                if($g[$state][$ch] -ne -1){
                    $failure = $f[$state]
                    while($g[$failure][$ch] -eq -1){
                        $failure = $f[$failure]
                    }

                    $failure = $g[$failure][$ch]
                    $f[$g[$state][$ch]] = $failure

                    $out[$g[$state][$ch]] = $out[$g[$state][$ch]] -bor $out[$failure];
                    $queue.Enqueue($g[$state][$ch])
                }
            }
        }

    }

    End{

         $Global:out = $out
         $Global:g = $g
         $Global:f = $f
         #$Global:states = $states

         
    }
}

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

    $g = $Global:g
    $f = $Global:f

    while($g[$answer][$ch] -eq -1){
        $answer = $f[$answer]
    }

    #Write-Verbose ([string]$g[$answer][$ch])
    return $g[$answer][$ch]

}

Function Search-Words{

    [cmdletBinding()]
    param(
        [parameter(Mandatory = $True)]
        [string[]]$array,

        [parameter(Mandatory = $True)]
        [string]$text

    )
    $out = $Global:out

    Build-MacthingMachine -InputStrings $array
    $currentState = 0

    for($i = 0; $i -lt $text.Length; $i++){
        $currentState = (Find-NextState -currentState $currentState -nextInput $text[$i])

        if($out[$currentState] -eq 0){continue}

        for($h = 0; $h -lt $array.Count; $h++){
            #Write-Verbose ("" + $out[$currentState]  + " "+ ($out[$currentState] -band (1 -shl $h) ))
            #Write-Verbose ("" + $currentState + " " +  $out[$currentState])
            Write-Verbose ($out[$currentState])
            if ($out[$currentState] -band (1 -shl $h)){ 
            #Write-Verbose (1 -shl $h)
            
                #Write-Verbose ([string]($out[$currentState] -band (1 -shl $h)))
                
                Write-Host ("word " + $array[$h] + " appears from " + [string]($i - $array[$h].Length +1) + " to " + $i)
            } 
        }
    }

}

$array = @("he", "she", "hers", "his")
$text = "ahishers"

search-Words -array $array -text $text -Verbose