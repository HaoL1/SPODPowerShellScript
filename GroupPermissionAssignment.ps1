#SharePoint online Admin site URL
$SPOAdmiURL = "https://hali3-admin.sharepoint.com/"
$AdminUser= "haoli@hali3.onmicrosoft.com"

#Url of the SharePoint Online Site
$SPOSiteURL = 'https://hali3.sharepoint.com/sites/teamtest'

#Set the admin user as the site collection admin
##Set-SPOUser -Site $SPOSiteURL -LoginName $AdminUser -IsSiteCollectionAdmin $true
##Write-Host -f Cyan "Add user $AdminUser as site collection administrator"

#User used as reference
$sourceUser = 'test1@hali3.onmicrosoft.com'
#The actual user that needs to be added to Groups
$targetUser = 'test6@hali3.onmicrosoft.com'

#Create a credential object
$cred = Get-Credential

#Connect to SharePoint Online using the credentials
Connect-SPOService -Url $SPOAdmiURL -Credential $cred

#Get the SharePoint Online Site Object
$site = Get-SPOSite $SPOSiteURL

#Get the user object of the reference user
$user = Get-SPOUser -Site $site -LoginName $sourceUser

#Loop through Groups and add the actual user
$user.Groups | Foreach-Object {
    
    #Fetch Group Object that the reference user is part of
    $group = Get-SPOSiteGroup -Site $site -Group $_
	Write-Host -f Cyan "Add user $targetUser to Group $($group.LoginName)"						         
    #Add 'ActualUser' to the same group that the reference user is part of
    Add-SPOUser -Site $SPOSiteURL -LoginName $targetUser  -Group $group.LoginName
       
}

#Remove the admin user from the site collection admin
##Set-SPOUser -Site $SPOSiteURL -LoginName $AdminUser -IsSiteCollectionAdmin $false
##Write-Host -f Red "Remove user $AdminUser as site collection administrator"