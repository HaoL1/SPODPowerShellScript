$RunTime = Get-Date -Format yyyy-MM-dd-hh-mm-ss
$scriptPath = "C:\Temp\27981743\"
$LogFile = $scriptPath+"Output\" + $RunTime + "_SiteAccessReport.csv"
$LogFileName = $scriptPath+"Output\" + $RunTime + "jobLog.log"
$credentialFile = $scriptPath+"O365Cred.txt"
$SPAssemblies = @(
    "$scriptPath\Dlls\Microsoft.SharePoint.Client.dll",
    "$scriptPath\Dlls\Microsoft.SharePoint.Client.Runtime.dll",
    "System"
)
#region Variables 
$AdminName = "haoli@hali3.onmicrosoft.com"
$tenant = 'hali3'
#$Password = "LhAccess1}"
$BatchSize = 2000
$expandGroupMember = $true
[array]$SitesTemplate = @('STS#0','EHS#1')
[array]$ModernSites = @('STS#3', 'SITEPAGEPUBLISHING#0', 'GROUP#0', 'POINTPUBLISHINGPERSONAL#0', 'SPSPERS#10', 'RedirectSite#0', 'TEAMCHANNEL#0')
$LibraryToExclude = @("Solution Gallery", "List Template Gallery", "Converted Forms", "Theme Gallery", "Web Part Gallery", "Master Page Gallery", "Form Templates", "Site Assets", "Site Pages", "Style Library", "App Packages")

#endregion Variables

$source = @"
using Microsoft.SharePoint.Client;
using System.Collections.Generic;
using System.Linq;

namespace AccessSharePointOnline
{
    public static class DataAccess
    {
        public static List<ListItem> GetLibraryData(ClientContext context, string ListTitle,int PageSize)
        {
            Web web = context.Web;
            List largeLibrary = web.Lists.GetByTitle(ListTitle);
            CamlQuery query = new CamlQuery();
            query.ViewXml = "<View Scope='RecursiveAll'><Query><OrderBy><FieldRef Name='ID' Ascending='TRUE'/></OrderBy></Query><RowLimit Paged='TRUE'>"+ PageSize + "</RowLimit></View>";

            List<ListItem> items = new List<ListItem>();
            ListItemCollectionPosition position = null;
            do
            {
                ListItemCollection listItems = null;
                query.ListItemCollectionPosition = position;
                listItems = largeLibrary.GetItems(query);
                context.Load(listItems,
                    _items => _items.ListItemCollectionPosition,_items=>_items.Include(
                        _item => _item.Id,
                        _item => _item.HasUniqueRoleAssignments,
                        _item => _item.FileSystemObjectType,
                        _item => _item["FileLeafRef"],                        
                        _item => _item["Created"],
                        _item => _item["Modified"]
                        ));
                context.ExecuteQuery();
                position = listItems.ListItemCollectionPosition;
                items.AddRange(listItems.ToList());

            }
            while (position != null);            
            return items;
        }        
    }
}
"@
Add-Type -TypeDefinition $source -ReferencedAssemblies $SPAssemblies

function Write-Log([string[]]$Message, [string]$LogFile = $Script:LogFile, [switch]$ConsoleOutput) {
    $Message = $Message + $Input
    If ($null -ne $Message -and $Message.Length -gt 0) {
        if ($LogFile -ne $null -and $LogFile -ne [System.String]::Empty) {
            Out-File -Append -FilePath $LogFile -InputObject "$Message"			
        }
        if ($ConsoleOutput -eq $true) {
            Write-Host "$Message"
        }
    }
}

#Function to Get Permissions Applied on a particular Object, such as: Web, List or Item
Function Get-Permissions($Object, $Ctx) {
    #Determine the type of the object
    Switch ($Object.TypedObject.ToString()) {
        "Microsoft.SharePoint.Client.Web" { $ObjectType = "Site" ; $ObjectURL = $Object.URL }
        "Microsoft.SharePoint.Client.ListItem" {
            $ObjectType = "List Item"
            #Get the URL of the List Item
            #Invoke-LoadMethod -Object $Object.ParentList -PropertyName "DefaultDisplayFormUrl"
            Get-PnPProperty -ClientObject $Object.ParentList -Property DefaultDisplayFormUrl
            #$Ctx.ExecuteQuery()
            $DefaultDisplayFormUrl = $Object.ParentList.DefaultDisplayFormUrl
            $ObjectURL = $("{0}{1}?ID={2}" -f $Ctx.Web.Url.Replace($Ctx.Web.ServerRelativeUrl, ''), $DefaultDisplayFormUrl, $Object.ID)
        }
        Default {
            $ObjectType = "List/Library"
            #Get the URL of the List or Library
            $Ctx.Load($Object.RootFolder)
            $Ctx.ExecuteQuery()           
            $ObjectURL = $("{0}{1}" -f $Ctx.Web.Url.Replace($Ctx.Web.ServerRelativeUrl, ''), $Object.RootFolder.ServerRelativeUrl)
        }
    }
  
    #Get permissions assigned to the object
    $Ctx.Load($Object.RoleAssignments)
    $Ctx.ExecuteQuery()
  
    Foreach ($RoleAssignment in $Object.RoleAssignments) {        
        #Get the Permission Levels assigned and Member
        Get-PnPProperty -ClientObject $RoleAssignment -Property RoleDefinitionBindings, Member
 
        #Get the Principal Type: User, SP Group, AD Group
        $PermissionType = $RoleAssignment.Member.PrincipalType
        $PermissionLevels = $RoleAssignment.RoleDefinitionBindings | Select-Object -ExpandProperty Name
 
        #Get all permission levels assigned (Excluding:Limited Access)
        $PermissionLevels = ($PermissionLevels | Where-Object { $_ –ne "Limited Access" }) -join ","
        If ($PermissionLevels.Length -eq 0) { Continue }
        #Check direct permissions
        if ($PermissionType -eq "User") {
            #Is the current user is the user we search for?
            $MemberEmail = $RoleAssignment.Member.LoginName.Replace("i:0#.f|membership|", "")                   
            Write-Host  -f Cyan "Found the User under direct permissions of the $($ObjectType) at $($ObjectURL)"                           
            #Send the Data to Report file
            "$($ObjectURL) `t $($MemberEmail) `t Direct Permission `t $($PermissionLevels)" | Out-File $LogFile -Append                    										
        }
                  
        Elseif ($PermissionType -eq "SharePointGroup") {            
            if (($expandGroupMember) -or ($RoleAssignment.Member.LoginName.StartsWith("SharingLinks"))) {
                #Get Group Members
                $GroupUsers = Get-PnPGroupMembers -Identity $RoleAssignment.Member.LoginName			            
                Foreach ($User in $GroupUsers) {                                     
                    #$SystemAccounts -notcontains $User.Title
                    if ($User.LoginName -like "*@*") {
                        $MemberEmail = $User.LoginName.Replace("i:0#.f|membership|", "")  
                        #Send the Data to Report file
                        "$($ObjectURL) `t $($MemberEmail)`t Member of '$($RoleAssignment.Member.LoginName)' Group `t $($PermissionLevels)" | Out-File $LogFile -Append								                							
                    }elseif ($User.PrincipalType -eq "SecurityGroup") {
                        #Get-PnPUnifiedGroupMembers need graph token
                        #https://www.sharepointdiary.com/2019/04/get-office-365-group-members-using-powershell.html
                        #$groupMembers=Get-PnPUnifiedGroupMembers -Identity $groupId
                        "$($ObjectURL) `t $($User.Title)`t Member of '$($RoleAssignment.Member.LoginName)' Group `t $($PermissionLevels)" | Out-File $LogFile -Append								                							
                    }
                    else {
                        Write-Log -LogFile $LogFileName -Message "Log the account:$($User.LoginName) with unique permission for $ObjectURL"  
                    }
                }
            }           
            else {
                "$($ObjectURL) `t $($RoleAssignment.Member.LoginName)`t Group Permission `t $($PermissionLevels)" | Out-File $LogFile -Append
            }						
        }
        Elseif ($PermissionType -eq "SecurityGroup") {            
            $GroupTitle =   $RoleAssignment.Member.Title               
            Write-Host  -f Cyan "Found the SecurityGroup under direct permissions of the $($ObjectType) at $($ObjectURL)"                           
            #Send the Data to Report file
            "$($ObjectURL) `t $($GroupTitle) `t Direct Permission `t $($PermissionLevels)" | Out-File $LogFile -Append                    										
        }
    }
}

#Function to Get Permissions of All List Items of a given List
Function Get-SPOListItemsPermission($List, $Ctx) {
    Write-host -f Yellow "`t `t Getting Permissions of List Items in the List:"$List.Title

    #$Query = New-Object Microsoft.SharePoint.Client.CamlQuery    
    #$Query = "<View Scope='RecursiveAll'><Query><OrderBy><FieldRef Name='ID' Ascending='TRUE'/></OrderBy></Query><RowLimit Paged='TRUE'>$BatchSize</RowLimit></View>"    
    
    $ListItems = [AccessSharePointOnline.DataAccess]::GetLibraryData($Ctx, $List.Title, $BatchSize)
    foreach ($ListItem in $ListItems) {      
        If ($ListItem.HasUniqueRoleAssignments -eq $True) {
            #Call the function to generate Permission report
            Get-Permissions -Object $ListItem $Ctx
        }
    }
        
}

#Function to Get Permissions of all lists from the web
Function Get-SPOListPermission($Web, $Ctx) {    
    $listColl = Get-PnPList -Web $Web -Includes HasUniqueRoleAssignments | Where-Object { $_.Hidden -eq $false } 
       
    foreach ($list in $listColl) {
        #Exclude System Lists        
        If (($list.Hidden -eq $False) -and ($LibraryToExclude -notcontains $list.Title)) { 
            Write-Host "Checking list $($list.Title)"
            #Get List Items Permissions
            Get-SPOListItemsPermission $list $Ctx
            if ($list.HasUniqueRoleAssignments -eq $true) {  
                #Call the function to check permissions
                Get-Permissions -Object $list $Ctx
            }
        }
        else {
            Write-Host "Exclude list $($list.Title)"
        }
    }	
}
#Function to Get Webs's Permissions from given URL
Function Get-SPOWebPermission($Web, $Ctx) {
    #Get all subsites of the site
    $webs = Get-PnPSubWebs -Recurse -Includes HasUniqueRoleAssignments       
    
    $web = Get-PnPWeb -Includes HasUniqueRoleAssignments
    #Call the function to Get Lists of the web
    Write-host -f Yellow "Checking the Permissions of Web "$Web.URL"..."
    if ($web.HasUniqueRoleAssignments -eq $true) {
        #Get the Root Web's Permissions    
        Get-Permissions -Object $Web $Ctx  
    }
     
    #Scan Lists with Unique Permissions
    Write-host -f Yellow "`t Getting the Permissions of Lists and Libraries in "$Web.URL"..."
    Get-SPOListPermission $Web $Ctx

    #Iterate through each subsite in the current web
    Foreach ($Subweb in $webs) {
        Connect-PnPOnline -Url $Subweb.Url -credentials $credentials
        $Ctx = Get-PnPContext
        $Subweb = Get-PnPWeb -Includes HasUniqueRoleAssignments
        #Get all subWeb's Permissions 
        if ($Subweb.HasUniqueRoleAssignments -eq $true) {
            #Get the Root Web's Permissions    
            Get-Permissions -Object $Subweb $Ctx  
        }                             
        #Scan Lists with Unique Permissions
        Write-host -f Yellow "`t Getting the Permissions of Lists and Libraries in "$Web.URL"..."
        Get-SPOListPermission $Subweb $Ctx
    }
}

#Step1: Use below cmdlet to create O365cred.txt:
$SecurePassword = Read-Host -Prompt "Enter password" -AsSecureString
$SecureStringAsPlainText = $SecurePassword | ConvertFrom-SecureString
If (!(Test-Path $credentialFile)) {
    $SecureStringAsPlainText | out-file $credentialFile
}
else {
    Clear-Content $credentialFile   
    $SecureStringAsPlainText | out-file $credentialFile 
}
# Step2: Then you can test it with below script:
#Import pwd 
$password = get-content $credentialFile | convertto-securestring
$credentials = New-Object -TypeName System.Management.Automation.PSCredential -argumentlist $AdminName, $password

# Validate identity submitted is a valid email address/upn format
Try { $Test = New-Object Net.Mail.MailAddress($AdminName) -ea stop }
Catch { "ERROR: Not a valid identity address (user@domain.com)"; break }

# Validate tenant name
If ($tenant -like "*.onmicrosoft.com") { $tenant = $tenant.split(".")[0] }
$AdminURL = "https://$tenant-admin.sharepoint.com"

# Verify if log file exists; if not, create
If (!(Test-Path $LogFile)) {    
    #Write-Log -Message "Identity,Url,Permissions" -LogFile $LogFile
    "URL `t Object `t PermissionType" | out-file $LogFile
}
else {
    Clear-Content $LogFile
    #Write-Log -Message "Identity,Url,Permissions" -LogFile $LogFile
    "URL `t Object `t PermissionType" | out-file $LogFile
}

# Connect-PnpOnline only doesn't prompt for creds if you pass it to Invoke-Expression
#$cmd = "Connect-PnPOnline -Url $($AdminUrl) -credentials `$credentials"
#Invoke-Expression $cmd
Connect-PnPOnline -Url $AdminUrl -credentials $credentials #-ReturnConnection

[array]$Sites = Get-PnPTenantSite -Filter "Status -eq 'Active'" | Select-Object Url, Template #-ExpandProperty Url,Template
$i = 1
Foreach ($Site in $Sites) {        
    #test single site  -and ($Site.Url -eq 'https://tenant.sharepoint.com/sites/ClassicTeam')
    if ($SitesTemplate -contains $Site.Template) {        
        $Url = $Site.Url
        Write-Progress -Activity "SharePoint Site Permissions Report" -Percent (($i / $Sites.Count) * 100) -CurrentOperation "Checking site $($Url)"		
        Write-Log -LogFile $LogFileName -Message "Checking site $Url"  
        $needReset = $false
        try {        
            try {
                Connect-PnPOnline -Url $Url -credentials $credentials			
                $checkAdmin = Get-PnPUser | ? Email -eq $AdminName
                if ($?) {
                    if ($checkAdmin.IsSiteAdmin -eq $false) {
                        Write-Host "Use has permission while not admin, add User $($AdminName) as admin to site $($Url)"
                        Connect-PnPOnline -Url $AdminUrl -credentials $credentials
                        Set-PnPTenantSite -Url $Url -Owners $AdminName
                        $needReset = $true
                        Write-Log -LogFile $LogFileName -Message "Need remove admin permission for the site: $Url, tenant admin account: $AdminName"  
                    }
                }
                else {
                    throw $error[0].Exception
                }						
            }
            catch {
                Write-Host "Add User $($AdminName) as admin to site $($Url)"
                Connect-PnPOnline -Url $AdminUrl -credentials $credentials
                Set-PnPTenantSite -Url $Url -Owners $AdminName
                $needReset = $true
                Write-Log -LogFile $LogFileName -Message "Need remove admin permission for the site: $Url, tenant admin account: $AdminName"
            }				
            # connect to ensure admin permission
            Connect-PnPOnline -Url $Url -credentials $credentials
            $Ctx = Get-PnPContext        	       
		            
            Get-SPOWebPermission $web $Ctx
            
        }
        catch {
            $_
            Write-Log -LogFile ErrorLog.txt -Message "Error connecting to site $($Url)."
        }
        if ($needReset) {
            Write-Host "restset User $($user) as admin to false in site $($Url) "		
            #Set-SPOUser -site $Url -LoginName $AdminName -IsSiteCollectionAdmin $false
            Write-Log -LogFile $LogFileName -Message "Start remove admin permission for the site: $Url, tenant admin account: $AdminName"
            Connect-PnPOnline -Url $Url -credentials $credentials
            Remove-PnPSiteCollectionAdmin -Owners $AdminName
            Write-Log -LogFile $LogFileName -Message "Remove admin permission for the site: $Url, tenant admin account: $AdminName"
        }
    }
    $i++	    
}
