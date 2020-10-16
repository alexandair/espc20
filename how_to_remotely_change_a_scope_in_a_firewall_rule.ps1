# How to remotely change a scope in a firewall rule

# When you work in a workgroup environment, Kerberos authentication is unavailable
# If windowmgmt VM and VM scale set instances are in the different subnets
# you need to modify a scope for the public profile of Windows Remote Management rule
# on the target instances. Do that using an RDP connection for the first instance
# You can connect now Windows Admin Center to that first instance 
# From now on, use a PowerShell tool in that conected machine to modify the scope using 
# the following commands

# Add the target computers to the TrustedHosts list setting
cd wsman:
cd .\localhost\Client
dir
# '192.168.3.7' is the private IP address of the second instance
# it's better to use a wildcard 192.168.3.*
New-Item ./TrustedHosts -Value '192.168.3.7'

# You need to authenticate with the explicit credentials (local admin on the target machine)
$cred = Get-Credential demoScale000003\azureuser # you need to specify a computer name

# create a CIM session
$cs = New-CimSession -ComputerName 192.168.3.7 -Credential $cred -Authentication Negotiate
$cs

# We are changing a scope for a private profile for WinRM Remote Management firewall rule
Get-NetFirewallRule -Name 'winrm-http-in-tcp-public' -CimSession $cs
Get-NetFirewallRule -Name 'winrm-http-in-tcp-public' -CimSession $cs | Get-NetFirewallAddressFilter
# By default, remote address is set to 'LocalSubnet'; you don't want to overwrite it, but to add
# an IP of the management WAC VM (windowsmgmt VM)
Get-NetFirewallRule -Name 'winrm-http-in-tcp-public' -CimSession $cs | Get-NetFirewallAddressFilter |
Set-NetFirewallAddressFilter -RemoteAddress "LocalSubnet","192.168.2.4"
# Check out the result
Get-NetFirewallRule -Name 'winrm-http-in-tcp-public' -CimSession $cs | Get-NetFirewallAddressFilter
