If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Warning "You do not have Administrator rights to run this script!`nPlease re-run this script as an Administrator!"
    Break
}

$prefix = "192.168.1"
$found
$addr1

ForEach ($Adapter in (Get-WmiObject Win32_NetworkAdapter -EnableAll -Filter "NetEnabled='True'")) {
    $Config = Get-WmiObject Win32_NetworkAdapterConfiguration -EnableAll -Filter "Index = '$($Adapter.Index)'"
    ForEach ($Addr in ($Config.IPAddress)) {  
        If ($Addr -match $prefix + '.[0-9]+') {
            $found = $Config
            $addr1 = $Addr
        }
    }
}

$ip_last_number = $addr1.Split('.')[3]
# Write-Output "WmiObject: " $found
Write-Output "IP: x.x.x.$ip_last_number"


$ips = @("$prefix.$ip_last_number", "192.168.10.$ip_last_number")
$masks = @('255.255.255.0', '255.255.255.0')


# Write-Output "IPs:" $ips

$found.DHCPEnabled = $false
$retval = $found.EnableStatic([string[]]$ips, $masks)
$found.SetGateways(@('192.168.0.3', '192.168.10.1'), @(3, 6))

$retval

#Write-Output "WmiObject: " $found
Write-Output $found.GateWays