$UserName = "vmstats@vsphere.local"
$PlainPassword = Get-Content $PSScriptRoot\vmware_host_stats.cred

Connect-VIServer 172.24.10.200 -User $UserName -Password $PlainPassword

$allvms = @()
$allhosts = @()
$hosts = Get-VMHost
$vms = Get-Vm

foreach($vmHost in $hosts){
  $hoststat = "" | Select HostName, Mem, CPU, DSUsed, net, iops
  $hoststat.HostName = $vmHost.name
  
  $cpu = Get-Stat -Entity ($vmHost) -IntervalMins 5 -MaxSamples 1 -stat cpu.usage.average
  $mem = Get-Stat -Entity ($vmHost) -IntervalMins 5 -MaxSamples 1 -stat mem.usage.average
  $net = Get-Stat -Entity ($vmHost) -IntervalMins 5 -MaxSamples 1 -stat net.usage.average
  $iops = Get-Stat -Entity ($vmHost) -IntervalMins 5 -MaxSamples 1 -stat disk.usage.average

  $ds = Get-Datastore -Name $vmHost'_datastore1'
    
  $dsused = Percentcal ($ds.CapacityMB-$ds.FreeSpaceMB) $ds.CapacityMB
  
  $hoststat.CPU = $cpu.Value
  $hoststat.Mem = $mem.Value
  $hoststat.DSUsed = [math]::round($dsused, 2)
  $hoststat.net = $net.Value
  $hoststat.iops = $iops.Value

  $allhosts += $hoststat
}
$allhosts | Select HostName, Mem, CPU, DSUsed, net, iops | ConvertTo-JSON > '\\os1\c$\inetpub\wwwroot\ops\datasources\vsphere.json'
