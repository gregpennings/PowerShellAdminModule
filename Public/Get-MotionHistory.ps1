function Get-MotionHistory {
<#  
.SYNOPSIS  Returns the vMotion/svMotion history    
.DESCRIPTION The function will return information on all
   the vMotions and svMotions that occurred over a specific
    interval for a defined number of virtual machines
.NOTES  Author:  Luc Dekens  
.PARAMETER Entity
   The vSphere entity. This can be one more virtual machines,
   or it can be a vSphere container. If the parameter is a
    container, the function will return the history for all the
   virtual machines in that container.
.PARAMETER Days
   An integer that indicates over how many days in the past
   the function should report on.
.PARAMETER Hours
   An integer that indicates over how many hours in the past
   the function should report on.
.PARAMETER Minutes
   An integer that indicates over how many minutes in the past
   the function should report on.
.PARAMETER Sort
   An switch that indicates if the results should be returned
   in chronological order.
.EXAMPLE
   PS> Get-MotionHistory -Entity $vm -Days 1
.EXAMPLE
   PS> Get-MotionHistory -Entity $cluster -Sort:$false
.EXAMPLE
   PS> Get-Datacenter -Name $dcName |
   >> Get-MotionHistory -Days 7 -Sort:$false
#>
 
  param(
    [CmdletBinding(DefaultParameterSetName="Days")]
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [VMware.VimAutomation.ViCore.Impl.V1.Inventory.InventoryItemImpl[]]$Entity,
    [Parameter(ParameterSetName='Days')]
    [int]$Days = 1,
    [Parameter(ParameterSetName='Hours')]
    [int]$Hours,
    [Parameter(ParameterSetName='Minutes')]
    [int]$Minutes,
    [switch]$Recurse = $false,
    [switch]$Sort = $true
  )
 
  begin{
    $history = @()
    switch($psCmdlet.ParameterSetName){
      'Days' {
        $start = (Get-Date).AddDays(- $Days)
      }
      'Hours' {
        $start = (Get-Date).AddHours(- $Hours)
      }
      'Minutes' {
        $start = (Get-Date).AddMinutes(- $Minutes)
      }
    }
    $eventTypes = "DrsVmMigratedEvent","VmMigratedEvent"
  }
 
  process{
    $history += Get-VIEventPlus -Entity $entity -Start $start -EventType $eventTypes -Recurse:$Recurse |
    Select CreatedTime,
    @{N="Type";E={
        if($_.SourceDatastore.Name -eq $_.Ds.Name){"vMotion"}else{"svMotion"}}},
    @{N="UserName";E={if($_.UserName){$_.UserName}else{"System"}}},
    @{N="VM";E={$_.VM.Name}},
    @{N="SrcVMHost";E={$_.SourceHost.Name.Split('.')[0]}},
    @{N="TgtVMHost";E={if($_.Host.Name -ne $_.SourceHost.Name){$_.Host.Name.Split('.')[0]}}},
    @{N="SrcDatastore";E={$_.SourceDatastore.Name}},
    @{N="TgtDatastore";E={if($_.Ds.Name -ne $_.SourceDatastore.Name){$_.Ds.Name}}}
  }
 
  end{
    if($Sort){
      $history | Sort-Object -Property CreatedTime
    }
    else{
      $history
    }
  }
}
