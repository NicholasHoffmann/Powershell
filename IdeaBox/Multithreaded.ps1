Function Start-Multithread{
    [cmdletBinding()]
    param(
        [parameter(Mandatory=$True)]
        $Command,
        $Threads
    )

    $ISS = [system.management.automation.runspaces.initialsessionstate]::CreateDefault()
    $RunspacePool = [runspacefactory]::CreateRunspacePool(1,20,$ISS,$Host)
    $RunSpacePool.Open()

    $PowershellThread = [powershell]::Create()
    
        
    $RunSpacePool.Close() | Out-Null
    $RunSpacePool.Dispose() | Out-Null


}