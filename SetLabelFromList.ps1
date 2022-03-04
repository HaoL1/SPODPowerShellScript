####Install MOdules If you haven't
#Install-Module -Name Microsoft.Online.SharePoint.PowerShell 
#Install-Module -Name PnP.PowerShell
#Install-Module -Name ExchangeOnlineManagement

#Set parameter values
$SharePointAdminUrl = "https://m365x941039-admin.sharepoint.com"
$AdminAccount = "admin@M365x941039.onmicrosoft.com"
$password = Get-Content "C:\Passwords\password.txt" | ConvertTo-SecureString 
$SharePointListSiteURL = "https://m365x941039.sharepoint.com/sites/HaoTestSite3"
$ListName = "TestList"

#Get credential
$cred = New-Object System.Management.Automation.PsCredential($AdminAccount,$password)
#Connect to SCC,SPO and PnP
#Connect-IPPSSession -Credential $cred
Connect-SPOService -Url $SharePointAdminUrl -Credential $cred
Connect-PnPOnline -Url $SharePointListSiteURL -Credentials $cred

#Get Site Url and Label Name from the list item.

$ListItems= Get-PnPListItem -List $ListName -PageSize 1000

Foreach($Item in $ListItems)
{
    Write-Host "====================================" -f White
    Write-Host " "
    Write-Host "Scanning the item"$Item["Title"] -f Green
    Write-Host " "

   #Check whether the item needs to apply label.
   If ($item["NeedToApply"] -eq "Need")
   {
        #Get the LabelName and SiteURL
        $LabelName=$item["LabelName"]
        $SiteUrl=$item["SiteUrl"]

        Write-Host "Apply"$LabelName "Label to"$Item["Title"] -f Green

        #Set the label on the site
        $Label = Get-Label | where {$_.name -eq $LabelName}
        Set-SPOSite -Identity $SiteUrl -SensitivityLabel $Label.Guid
        
        #Set the item as completed.
        Set-PnPListItem -List $ListName -Identity $item.Id -Values @{"NeedToApply" = "Completed"} | Out-Null
   }
   Else
   {
        Write-Host "No need to apply Labels" -f Yellow
   }

}

