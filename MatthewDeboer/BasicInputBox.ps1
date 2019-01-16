if ( ($dest -eq $null) -or ($src -eq $null) ) {

      [void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')  

      $src = [Microsoft.VisualBasic.Interaction]::InputBox("Enter the name of the source computer", "Source Computer")  

      $dest = [Microsoft.VisualBasic.Interaction]::InputBox("Enter the name of the destination computer", "Destinaton Computer")
 }