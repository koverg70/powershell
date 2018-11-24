# 
# Scriptum hálózat konfigurátor
# Figyelem! Csak akkor működik, ha a gépnek van 192.168.0.x IP címe.
# A 192.168.0.x-es subnet a Telekom vezetékes Internet subnetje
# A 192.168.10.x-es subnet peding a Telenor mobil Internet subnetje
#
# Továbbfejlesztés: 
#   1. az Internet kapcsolat meglétének tesztelése: https://stackoverflow.com/questions/38912095/how-to-do-something-if-a-job-has-finished
#   2. a DHCP-re átváltás (ha a gépet más hálózatba is dugjuk)
#   3. több hálózati adapter kezelése (ha pl. vezetékes és Wifi adapter is van a gépben - mondjuk a Scriptum laptop)
#   4. consol elrejtése: https://stackoverflow.com/questions/40617800/opening-powershell-script-and-hide-command-prompt-but-not-the-gui

[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")

If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{   
  $arguments = "& '" + $myinvocation.mycommand.definition + "'"
  Start-Process powershell -Verb runAs -ArgumentList $arguments
  Break
}

$prefix = "192.168.0"
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
# Write-Output "IP: x.x.x.$ip_last_number"


$Form1 = New-Object System.Windows.Forms.Form
$Form1.ClientSize = New-Object System.Drawing.Size(407, 390)
$form1.topmost = $true
$form1.Text = "Scriptum Internet konfigurátor"

$computerNames = @("Vezetékes Internet (Telekom)","Mobil internet (Telenor)")
# computerNames = @("Vezetékes Internet (Telekom)","Mobil internet (Telenor)","Külső hálózat (DHCP)")
$comboBox1 = New-Object System.Windows.Forms.ComboBox
$comboBox1.Location = New-Object System.Drawing.Point(25, 55)
$comboBox1.Size = New-Object System.Drawing.Size(350, 310)
foreach($computer in $computerNames)
{
  $comboBox1.Items.add($computer)
}
$Form1.Controls.Add($comboBox1)

$Button = New-Object System.Windows.Forms.Button
$Button.Location = New-Object System.Drawing.Point(25, 20)
$Button.Size = New-Object System.Drawing.Size(98, 23)
$Button.Text = "Átváltás"
$Button.add_Click({
  # $comboBox1.SelectedItem.ToString()
  $label.Text = "Feldolgozás..."
  if ($comboBox1.SelectedIndex -eq 0) {
    $ips = @("$prefix.$ip_last_number", "192.168.10.$ip_last_number")
    $masks = @('255.255.255.0', '255.255.255.0')
    $found.DHCPEnabled = $false
    $found.EnableStatic([string[]]$ips, $masks)
    $found.SetGateways(@('192.168.0.3', '192.168.10.1'), @(3, 6))
    $found.SetDNSServerSearchOrder(@('192.168.0.133', '8.8.8.8'))
    $label.Text = "Telekom kiválasztva"
  } elseif ($comboBox1.SelectedIndex -eq 1) {
    $ips = @("$prefix.$ip_last_number", "192.168.10.$ip_last_number")
    $masks = @('255.255.255.0', '255.255.255.0')
    $found.DHCPEnabled = $false
    $found.EnableStatic([string[]]$ips, $masks)
    $found.SetGateways(@('192.168.0.3', '192.168.10.1'), @(6, 3))
    $found.SetDNSServerSearchOrder(@('192.168.0.133', '8.8.8.8'))
    $label.Text = "Telenor (mobil) kiválasztva"
  } elseif ($comboBox1.SelectedIndex -eq 2) {
    $found.EnableDHCP()
    $found.SetDNSServerSearchOrder(@())
    $label.Text = "DHCP kiválasztva"
  }
})
$Form1.Controls.Add($Button)

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(25, 100)
$label.Size = New-Object System.Drawing.Size(350, 310)
$label.Text = "IP: x.x.x.$ip_last_number"

If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    $label.Text = "A sikeres beállításhoz adminisztátori jogosultság szükséges!"
    $label.ForeColor = "Red"
    $Button.Enabled = $false
}


$Form1.Controls.Add($label)

[void]$form1.showdialog()