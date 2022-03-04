#Load SharePoint CSOM Assemblies
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"
  
#Variables for Processing
$SiteURL = "https://hali3.sharepoint.com/sites/CreateFromTeam-test"
$UserAccount = "haoli@hali3.onmicrosoft.com"
$GroupName="CreateFromTeam - test Owners"
 
#Setup Credentials to connect
$Cred = Get-Credential
$Cred = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($Cred.UserName,$Cred.Password)
 
Try {
    #Setup the context
    $Ctx = New-Object Microsoft.SharePoint.Client.ClientContext($SiteURL)
    $Ctx.Credentials = $Cred
     
    #Get the Web and Group
    $Web = $Ctx.Web
    $Group= $Web.SiteGroups.GetByName($GroupName)
 
    #ensure user sharepoint online powershell - Resolve the User
    $User=$web.EnsureUser($UserAccount)
 
    #Add user to the group
    $Result = $Group.Users.AddUser($User)
    $Ctx.Load($Result)
    $Ctx.ExecuteQuery()
 
    write-host  -f Green "User '$UserAccount' has been added to '$GroupName'"
}
Catch {
    write-host -f Red "Error Adding user to Group!" $_.Exception.Message
}


