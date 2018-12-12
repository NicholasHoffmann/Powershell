<#

Written by Nicholas Hoffmann
This is an implementation of the Aho-Corasick Algorithm in powershell
for string matching



original code from https://www.geeksforgeeks.org/aho-corasick-algorithm-pattern-searching/
Get-Content C:\Projects\PowershellNotUploaded\FullUsers.txt

#>

$Command = {
    $Words = [string[]](Get-Content C:\Projects\PowershellNotUploaded\FullUsers.txt)
    
    $String = "nihoffma"

    search-Words -StringArray $Words -String $String -EqualizeTextToStandardChars -MaxStates 10000
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

    #Builds the string MatchingMachine
    Function Build-MacthingMachine{

        [cmdletBinding()]
        param(
            [Parameter(Mandatory = $true)]
            [string[]]$InputStrings,

            [parameter(Mandatory = $false)]
            [int]$MaxStates,

            [parameter(Mandatory = $false)]
            [int]$MaxCharacters

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

    $args = Build-MacthingMachine -InputStrings $StringArray -MaxStates $MaxStates -MaxCharacters $MaxCharacters

    $out = $args[0]
    $goto = $args[1]
    $Failure = $args[2]

    
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

    return $Output
}

& $command

