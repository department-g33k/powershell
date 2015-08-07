$UserName = "vmstats@vsphere.local"
$PlainPassword = Get-Content $PSScriptRoot\vmware_stats_to_array.cred

Connect-VIServer 172.24.10.200 -User $UserName -Password $PlainPassword
Get-Stat -Entity (Get-VMHost -Location production.vsphere.local) -IntervalMins 5 -stat cpu.usage.average -MaxSamples 1 | Select -Property Entity, @{N='CPU';E={$_.Value}}
#$MEM = Get-Stat -Entity (Get-VMHost -Location production.vsphere.local) -IntervalMins 5 -stat mem.usage.average -MaxSamples 1 | Select -Property Entity, @{N='MEM';E={$_.Value}}
#$STR = Get-Datastore -Location production.vsphere.local | Select -Property @{N="Entity"; E={$_.Name.substring(0,11)}}, CapacityGB, FreeSpaceGB 
#$NET = Get-Stat -Entity (Get-VMHost -Location production.vsphere.local) -IntervalMins 5 -stat net.usage.average -MaxSamples 1 | Select -Property Entity, @{N='NET';E={$_.Value}}
#$IOPS = Get-Stat -Entity (Get-VMHost -Location production.vsphere.local) -IntervalMins 5 -stat disk.usage.average -MaxSamples 1 | Select -Property Entity, @{N='IOPS';E={$_.Value}}
#Join-Object -Left $CPU -Right $MEM -leftJoinPropert Entity -RightJoinProperty Entity -Type OnlyIfInBoth -RightProperties MEM