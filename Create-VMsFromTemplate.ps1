param(
    [string]$vCenterServer = "wdc-12-1d2080-vc01.h2o-93-15080.h2o.vmware.com",
    [string]$User = "svc.tco-automation@vmware.com",
    [string]$Password = "TKH98yLp!232R@.o!ag",
    [string]$TemplateName = "vmbased-cpn-DND",
    [string]$DatacenterName = "wdc-12-1d2080-vc01",
    [string]$DatastoreName = "wdc-12-1d2080-vc01cl01-vsan",
    [string]$NetworkName = "msddc-012",
    [int]$NumVMs = 16,
    [string]$VMNamePrefix = "ptp-cpn-"
)

# Load PowerCLI module
Import-Module VMware.PowerCLI

# Ignore SSL Certificate warnings
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false

# Connect to vCenter
Write-Host "Connecting to vCenter..."
Connect-VIServer -Server $vCenterServer -User $User -Password $Password

# List all templates for verification
#Write-Host "Listing all templates..."
#Get-Template | Select-Object Name, @{Name="Folder";Expression={$_.Folder.Name}}, @{Name="Datacenter";Expression={$_.Datacenter.Name}}

# List all datastores for verification
#Write-Host "Listing all datastores..."
#Get-Datastore | Select-Object Name, @{Name="Folder";Expression={$_.Folder.Name}}, @{Name="Datacenter";Expression={$_.Datacenter.Name}}

# List all networks for verification
#Write-Host "Listing all networks..."
#Get-VirtualPortGroup | Select-Object Name, @{Name="Folder";Expression={$_.Folder.Name}}, @{Name="Datacenter";Expression={$_.Datacenter.Name}}

# Verify and get necessary objects
$template = Get-Template -Name $TemplateName
if (-not $template) {
    Write-Host "Template '$TemplateName' not found."
    exit
}

$datacenter = Get-Datacenter -Name $DatacenterName
$datastore = Get-Datastore -Name $DatastoreName -Location $datacenter
if (-not $datastore) {
    Write-Host "Datastore '$DatastoreName' not found."
    exit
}

# Verify the network
$network = Get-VirtualPortGroup | Where-Object { $_.Name -eq $NetworkName }
if (-not $network) {
    Write-Host "Network '$NetworkName' not found."
    exit
}
# Get the cluster and resource pool
$cluster = Get-Cluster -Location $datacenter
$resourcePool = Get-ResourcePool -Name "Resources" -Location $cluster
if (-not $resourcePool) {
    Write-Host "Resource Pool 'Resources' not found."
    exit
}

# Create VMs
for ($i = 1; $i -le $NumVMs; $i++) {
    $vmName = "$VMNamePrefix$i"
    Write-Host "Creating VM: $vmName from template: $TemplateName"

    $vm = New-VM -Name $vmName `
           -Template $template `
           -VMHost (Get-VMHost | Get-Random) `
           -Datastore $datastore `
           -NetworkName $network.Name `
           -ResourcePool $resourcePool

    Write-Host "Powering on VM: $vmName"
    Start-VM -VM $vm
}

# Disconnect from vCenter
Write-Host "Disconnecting from vCenter..."
Disconnect-VIServer -Server $vCenterServer -Confirm:$false

Write-Host "VM creation process completed."

