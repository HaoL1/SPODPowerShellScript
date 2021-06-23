#Get Cedential
##Replace TenantURL with yours
$TenantURL = "https://hali3-admin.sharepoint.com" 
$Cred = Get-Credential
 
#Connect to SPO
Connect-SPOService -Url $TenantURL -Credential $Cred
#Connect to AzureAD
Connect-AzureAD -Credential $Cred
#Get all the sites that have groups.
$SPSites = Get-SPOSite -Limit All | where{$_.Template -eq "GROUP#0"}
#Identify the sites.
foreach ($i in $SPSites)
{
    $GroupID = (Get-SPOSite -Identity $i).GroupID
    Try{
        $test = Get-AzureADGroup -ObjectId $GroupID
        $SiteWithGroup = (Get-SPOSite -Identity $i).url
        $SiteWithGroup | Out-File -Append C:\SiteWithGroup.txt
        $SiteWithGroup = $null
    }Catch{
        $SiteWithoutGroup  = (Get-SPOSite -Identity $i).url
        $SiteWithoutGroup | Out-File -Append C:\SiteWithoutGroup.txt
        $SitewithoutGroup = $null
        }
}
