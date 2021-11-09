

# Variables
$modulesdir = 'C:\Modules\'

# If PowerCLI module exist, do nothing, if it doesn't, download and install!
if (Get-Module -ListAvailable -Name VMware.PowerCLI) {
    Write-Host "Module already exists, no need to download."
} 
else {
    Write-Host "Module does not exist, downloading!"
    Save-Module -Name VMware.PowerCLI -Path C:\Modules\
    Install-Module -Name VMware.PowerCLI
}

# If modules directory does not exist, make directory
if (!($modulesdir | Test-Path)) { 
    mkdir C:\Modules\
}

# Set to ignore invalid ssl certificates if self-certificate
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false

# prompt for local ip to esxi
$ESXiIP = Read-Host -Prompt 'Input ESXi IP address: '

# Connect to the ESXi and enter credentials when prompted
connect-viserver $ESXiIP

# Get list of ESXi hosts and respective Serial Number
$esxlist = get-vmhost
foreach($Esx in $esxlist){
$esxcli=Get-EsxCli -VMHost $Esx
write-host $Esx.Name $esxcli.hardware.platform.get().SerialNumber
}

# END OF FILE
