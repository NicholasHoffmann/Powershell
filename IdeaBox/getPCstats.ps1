$Computers = Get-Content (join-path -Path $PSScriptRoot -ChildPath PCs.txt)

foreach($computer in $computers){
    if(Test-Connection -ComputerName $computer -Quiet -Count 2){
        $C = (gwmi -Class Win32_logicalDisk -ComputerName $computer -Filter "DeviceID='C:'" | Select-Object Freespace, Size)
        $C.Freespace = $C.Freespace/[math]::pow(1024,3)
        $C.Size = $C.Size/[math]::pow(1024,3)
        $M = (gwmi -Class Win32_PhysicalMemory -ComputerName $computer | Select-Object Capacity)
        $slotsUsed = 0
        $totalRam = 0
        if($m.length -ne $null){
        for($i = 0; $i -lt $M.length; $i++){
            $M[$i].capacity = $M[$i].capacity/[math]::pow(1024,3)
            $totalRam += $M[$i].capacity
            $slotsUsed++
        }}
        else{$totalRam += $M.capacity/[math]::pow(1024,3); $slotsUsed = 1}
        $out = New-Object psobject -Property @{
            Computer = $computer
            Freespace = $c.Freespace
            Size = $C.Size
            Ram = $totalRam
            slotsUsed = $slotsUsed
        }
        $out
    }
    else{"no connection"}
}

