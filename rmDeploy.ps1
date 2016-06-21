Login-AzureRmAccount

$global:bagoName = "bagodev"
$global:bagoiteration = "6"
$rgName = "TheBoat"
$rg = Get-AzureRmResourceGroup
$location = $rg.Location

function bagofy ([string]$item )
{
    $retval = [System.String]::Concat($global:bagoprefix, $global:bagoIteration, $item)
    return $retval
}

$subnet1Name = bagofy("Subnet")
$vnetSubnetAddressPrefix = "10.0.0.0/24"
$nicname = bagofy("nic")
$vnetName = bagofy("vnet")
$vnetAddressPrefix = "10.0.0.0/24"
$storageAccName = "theboat1676"


$pipName = bagofy("pip")

$pip = New-AzureRmPublicIpAddress -Name $pipName -ResourceGroupName $rgName -Location $location -AllocationMethod Dynamic -Force

$subnetconfig = New-AzureRmVirtualNetworkSubnetConfig -Name $subnet1Name -AddressPrefix $vnetSubnetAddressPrefix

$vnet = New-AzureRmVirtualNetwork -Name $vnetName -ResourceGroupName $rgName -Location $location -AddressPrefix $vnetAddressPrefix -Subnet $subnetconfig -Force

$nic = New-AzureRmNetworkInterface -Name $nicname -ResourceGroupName $rgName -Location $location -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip.Id -Force

#newVM


#Enter a new user name and password in thp for the following
$cred = Get-Credential
$vmName = bagofy("xama")

$vmConfig = New-AzureRmVMConfig -VMName $vmName -VMSize "Standard_DS11_v2"


#Set the Windows operating system configuration and add the NIC
$vm = Set-AzureRmVMOperatingSystem -VM $vmConfig -Windows -ComputerName $vmName -Credential $cred -ProvisionVMAgent -EnableAutoUpdate -WinRMHttp  

$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $nic.Id



#Get the storage account where the captured imatored
$storageAcc = Get-AzureRmStorageAccount -ResourceGroupName $rgName -AccountName $storageAccName
$osDiskName = bagofy([System.DateTime]::UtcNow.ToString("yyyyMMddHHMM"))

$osDiskUri = '{0}vhds/{1}{2}.vhd' -f $storageAcc.PrimaryEndpoints.Blob.ToString(), $vmName.ToLower(), $osDiskName

#Configure the OS disk to be created from image (-CreateOption fromImage) and give the URL of the captured image VHD for the -SourceImageUri parameter.
##We found this URL in the local JSON template in the previous sections.
#$vm = Set-AzureRmVMOSDisk -VM $vmConfig -Name $osDiskName -VhdUri $osDiskUri -CreateOption fromImage -SourceImageUri https://theboat1676.blob.core.windows.net/system/Microsoft.Compute/Images/backup-vhd/bagodev-osDisk.9a0157cc-2270-41b8-ac2b-a2a64403d3a9.vhd -Windows
$vm
$vm = Set-AzureRmVMOSDisk -VM $vmConfig -Name "osDisk" -VhdUri $osDiskUri -CreateOption fromImage -SourceImageUri https://theboat1676.blob.core.windows.net/system/Microsoft.Compute/Images/backup-vhd/bagodev-osDisk.9a0157cc-2270-41b8-ac2b-a2a64403d3a9.vhd -Windows

$vm
#Create the new VM
New-AzureRmVM -ResourceGroupName $rgName -Location $location -VM $vm
