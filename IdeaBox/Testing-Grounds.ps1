<#
$Root = Split-Path $PSScriptRoot -Parent
$Path = Join-Path -Path $Root -ChildPath Modules\WMI-Collection.psm1
Import-Module -Name $Path
#>

Measure-Object -Line -InputObject C:\Projects\Powershell\CopyADComputer\Copy-ADComputer.ps1