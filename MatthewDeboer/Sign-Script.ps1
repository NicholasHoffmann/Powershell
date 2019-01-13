 Function Sign-Script ($filename)
 {
  <#--------------------------------------------------------------------------
      FUNCTION.......:  Sign-Script
      PURPOSE........:  Signs a PowerShell script.
      ARGUMENTS......:  Script file name.
      EXAMPLE........:  Sign-Script script.ps1
      REQUIREMENTS...:  Current user must have a valid code signing
        certificate in their certificate store.
 #>

 #rename file
 $tmp = split-path $filename
 $tmp = $tmp + "\tmp.ps1"
 
 Rename-Item $filename $tmp
  
 #write it back with the correct encoding
 Get-Content $tmp | out-file $filename -encoding utf8
  
 #delete the old
 Remove-Item $tmp
  
 #sign new file
 $cert = @(gci cert:\currentuser\my -codesigning)[0]
 Set-AuthenticodeSignature $filename $cert –TimestampServer http://timestamp.verisign.com/scripts/timstamp.dll
 }