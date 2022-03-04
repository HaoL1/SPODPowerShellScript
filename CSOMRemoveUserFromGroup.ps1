#Load SharePoint CSOM Assemblies
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"
 
#sharepoint online remove user from site collection powershell
Function Remove-UserFromGroup()
{
  param
    (
        [Parameter(Mandatory=$true)] [string] $SiteURL,
        [Parameter(Mandatory=$true)] [string] $GroupName,
        [Parameter(Mandatory=$true)] [string] $UserID
    )
   Try {
        $Cred= Get-Credential
        $Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($Cred.Username, $Cred.Password)
 
        #Setup the context
        $Ctx = New-Object Microsoft.SharePoint.Client.ClientContext($SiteURL)
        $Ctx.Credentials = $Credentials
         
        #Get the User
        $User=$Ctx.web.EnsureUser($UserID)
        $Ctx.Load($User)
        #Get the Group
        $Group=$Ctx.web.SiteGroups.GetByName($GroupName)
        $Ctx.Load($Group)
        $Ctx.ExecuteQuery()
 
        #Check if user member of the group
        $IsMember = $False
        $GroupUsers = $Group.Users
        $Ctx.Load($GroupUsers)
        $Ctx.ExecuteQuery()
        Foreach($GrpUser in $GroupUsers){
            if($GrpUser.id -eq $User.Id)
            {
                $IsMember = $True
            }
        }
        if($IsMember -eq $False)
        {
            Write-host "User Doesn't Exists in the Group!" -ForegroundColor Yellow
        }
        else
        {
            #Remove user from the group
            $Group.Users.RemoveByLoginName($User.LoginName)
            $Ctx.ExecuteQuery()
            Write-host "User Removed from the Group Successfully!" -ForegroundColor Green
        }
    }
    Catch {
        write-host -f Red "Error Removing User from Group!" $_.Exception.Message
    }
}
 
#Set parameter values
$SiteURL = "https://hali3.sharepoint.com/sites/CreateFromTeam-test"
$GroupName="CreateFromTeam - test Owners"
$UserID="haoli@hali3.onmicrosoft.com"
 
#Call the function to remove user from group
Remove-UserFromGroup -SiteURL $SiteURL -GroupName $GroupName -UserID $UserID

