


# 1.User:
#Get Cedential
##Replace TenantURL with yours
$TenantURL = "https://hali3-admin.sharepoint.com" 
$Cred = Get-Credential
 
#Connect to SPO
Connect-SPOService -Url $TenantURL -Credential $Cred
#Set OneDrive NoAccess/Unlock
$AllOneDrivesite=Get-SPOSite -IncludePersonalSite $true -Limit all -Filter "Url -like '-my.sharepoint.com/personal/'"
##Replace "C:\owner.txt" with yours.
$Content=Get-Content C:\owner.txt
foreach ($account in $AllOneDrivesite) {
    foreach ($owner in $Content){ 
        if($owner -eq $account.owner){
            echo $account.Url
##Replace "NoAccess" with "Unlock" if you want to re-enable OneDrive of these users. 
            Set-SPOSite -Identity $account.url -LockState "NoAccess"
            echo "Setting finished"
        }
    }
}

# 2.O365 group:
#Get Cedential
$Cred = Get-Credential
#Connect to AzureAD
Connect-AzureAD -Credential $Cred
#Export all group members
##Replace "Teamtest" with your group name
$group = Get-AzureADGroup -SearchString "Teamtest"
$member = Get-AzureADGroupMember -ObjectId $group.ObjectId
##Replace "C:\1.txt" with your path of created .txt file
$member.UserPrincipalName | Out-File C:\1.txt
echo "Export Group finished"
#Connect to SPO
##Replace TenantURL with yours
$TenantURL = "https://hali3-admin.sharepoint.com" 
Connect-SPOService -Url $TenantURL -Credential $Cred
#Set OneDrive NoAccess/Unlock
$AllOneDrivesite=Get-SPOSite -IncludePersonalSite $true -Limit all -Filter "Url -like '-my.sharepoint.com/personal/'"
##Replace "C:\1.txt" with your path of created .txt file
$Content=Get-Content C:\owner.txt
foreach ($account in $AllOneDrivesite) {
    foreach ($owner in $Content){ 
        if($owner -eq $account.owner){
            echo $account.Url
##Replace "NoAccess" with "Unlock" if you want to re-enable OneDrive of these users. 
            Set-SPOSite -Identity $account.url -LockState "NoAccess"
            echo "Setting finished"
        }
    }
}





