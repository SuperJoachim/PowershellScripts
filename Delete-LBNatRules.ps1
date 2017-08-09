<#
.Synopsis
   Delete multiple NAT rules on an Azure Loadbalancer. 
.DESCRIPTION
   Gives the possibility to delete multiple NAT rules on an Azure Loadbalancer. Select Frontend or Backendport and the script will delete every match in the resource group provided.
.EXAMPLE
   Delete-LBNatRules.ps1 -ResourceGroup "NameOfResourceGroup" -BackendPort 3389
.EXAMPLE
   Delete-LBNatRules.ps1 -ResourceGroup "NameOfResourceGroup" -FrontendPort 6578
#>

param (
    [Parameter(Mandatory=$true)][string]$ResourceGroup,
    [Parameter()][string]$BackendPort,
    [Parameter()][string]$FrontendPort
)

$LoadBalancers = Get-AzureRmLoadBalancer -ResourceGroupName $ResourceGroup



foreach($LB in $LoadBalancers) {
    $LoadBalancerNatRules = $LB | Get-AzureRmLoadBalancerInboundNatRuleConfig

    if($FrontendPort) {
        $LBrulesList = $LoadBalancerNatRules | ? {$_.FrontendPort -eq $FrontendPort}
    }
    elseif($BackendPort) {
        $LBrulesList = $LoadBalancerNatRules | ? {$_.BackendPort -eq $BackendPort}
    }
    else {
        Write-Host "Please provide Backend or Frontend port"
        return
    }

    foreach($LBRuleToRemove in $LBrulesList) {
        Write-Host "Removing rule:" $LBRuleToRemove.Name "source:"$LBRuleToRemove.FrontendPort"target:"$LBRuleToRemove.BackendPort"on loadbalancer:" $LB.Name
        Remove-AzureRmLoadBalancerInboundNatRuleConfig -Name $LBRuleToRemove.Name -LoadBalancer $LB
        write-host "Rule removed." -ForegroundColor Cyan
    }
}
