# Install PnP online powershell from Install-Module SharePointPnPPowerShellOnline
 
#Config Variables
 
$SiteURL = "<SiteURL>" # Provide the site URL
$GroupName="test Members"  # Name of the group
$UserLoginID="" # External user who is added to the AAD
 
#Connect to PNP Online
Connect-PnPOnline -Url $SiteURL -Credentials (Get-Credential)
 
$web = Get-PnPWeb
$Ctx = Get-PnPContext
$Ctx.Load($web)
$Ctx.ExecuteQuery()
 
$user = $web.EnsureUser($UserLoginID)
$Ctx.Load($user)
$ctx.ExecuteQuery()
 
#sharepoint online powershell to add user to group
Add-PnPUserToGroup -LoginName $UserLoginID -Identity $GroupName


###################

#The below script first creates the Sharepoint group with View permission.
#Then checks user who accepted invitation "YY" time ago (that is send from AAD)
#Then need to add the accepted user into the SharePoint group:
==============================
## DISCLAIMER:
## Copyright (c) Microsoft Corporation. All rights reserved. This
## script is made available to you without any express, implied or
## statutory warranty, not even the implied warranty of
## merchantability or fitness for a particular purpose, or the
## warranty of title or non-infringement. The entire risk of the
## use or the results from the use of this script remains with you
 
 
# Install PnP online powershell from Install-Module SharePointPnPPowerShellOnline
# the script will create 50 SharePoint groups from an existing group with view only permissions
 
# Config Variables
 
$SiteURL = Read-host "provide the site collection URL" # Provide the site URL
$GroupName= Read-host "provide the name of the group to copy"  # Name of the group
$username = Read-host "Provide the site collection admin"
$owner = Read-Host "provide the account who will be the owner of the group"
 
 
$creds = Get-Credential -UserName $username -Message A
 
 
#Connect to PNP Online
Connect-PnPOnline -Url $SiteURL -Credentials $creds
 
 
# create 50 groups
for ($i = 5; $i -le 55; $i++)
{
    $r = $GroupName+"$i"
    Write-Host "Creating group" $r
 
 
    $g = New-PnPGroup -Title $r -Owner $owner
    $role = "View only"
   
    Write-Host "adding" $role "perms to the group" $r -ForegroundColor Green
    Set-PnPGroupPermissions -Identity $g -AddRole $role
 
 
}
 ==================================================
 
#To get a list of users who accepted invitation 5 mins ago(can be changed according to CX requirement) ago:​
Connect-AzureAD
$5minutesago=(Get-Date).AddMinutes(-1440)
$rightNow=Get-Date
$AADUsers=Get-AzureADUser-Filter "userType eq 'Guest'"-All $true|?{$_.RefreshTokensValidFromDateTime-gt$5minutesago-and$_.RefreshTokensValidFromDateTime-lt$rightNow}|where{$_.UserType-eq'Guest'}#| Select-Object DisplayName, UserState, UserType, RefreshTokensValidFromDateTime
 
foreach($aaduserin$AADUsers)
{
$aaduser.Mail
   # Do work here
}
 
#do work here -needs adding these users to SharePoint online group
 
#Currently we are helping customer with first script ie creating 50 SharePoint groups:
