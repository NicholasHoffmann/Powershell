
$Root = Split-Path $PSScriptRoot -Parent
$Path = Join-Path -Path $Root -ChildPath Modules\WMI-Collection.psm1
Import-Module -Name $Path
