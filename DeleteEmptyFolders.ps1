#Get the numbers of empty folders

#Load SharePoint CSOM Assemblies
$packagesPath = "C:\Program Files\WindowsPowerShell\Modules\SharePointPnPPowerShellOnline\3.13.1909.0"
Add-Type -Path ($packagesPath + "/Microsoft.SharePoint.Client.dll")
Add-Type -Path ($packagesPath + "/Microsoft.SharePoint.Client.Runtime.dll")
#Parameters
$SiteURL = "<SiteURL>"
$ListName="Documents"
   
#Get Credentials to connect
$Cred= Get-Credential
    
#Setup the context
$Ctx = New-Object Microsoft.SharePoint.Client.ClientContext($SiteURL)
$Ctx.Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($Cred.Username, $Cred.Password)
   
#Get the List
$List = $Ctx.Web.lists.GetByTitle($ListName)
  
#Define the CAML Query to get folders
$Query = New-Object Microsoft.SharePoint.Client.CamlQuery
$Query.ViewXml = "@
<View Scope='RecursiveAll'>
    <Query>
        <Where>
            <And>
                <And>
                    <Eq><FieldRef Name='ContentType' /><Value Type='Text'>Folder</Value></Eq>
                    <Eq><FieldRef Name='ItemChildCount' /> <Value Type='Counter'>0</Value></Eq>
                </And>
                <Eq><FieldRef Name='FolderChildCount' /> <Value Type='Counter'>0</Value></Eq>                   
            </And>
        </Where>
    </Query>
</View>"
  
#Get All List Items matching the query
$Folders = $List.GetItems($Query)
$Ctx.Load($Folders)
$Ctx.ExecuteQuery()
  
Write-host "Total Number of Empty Folders:"$Folders.count
  
#Loop through each List Item
ForEach($Folder in $Folders)
{
    Write-host $Folder.FieldValues.FileRef
}

###################

#Delete the empty folders

#Load SharePoint CSOM Assemblies
$packagesPath = "C:\Program Files\WindowsPowerShell\Modules\SharePointPnPPowerShellOnline\3.13.1909.0"
Add-Type -Path ($packagesPath + "/Microsoft.SharePoint.Client.dll")
Add-Type -Path ($packagesPath + "/Microsoft.SharePoint.Client.Runtime.dll")
 
Function Delete-SPOEmptyFolders([Microsoft.SharePoint.Client.Folder]$Folder)
{
    #Get All Sub-Folders from the given Folder
    $SubFolders = $Folder.Folders
    $Ctx.Load($SubFolders)
    $Ctx.ExecuteQuery()
 
    #Process Each Sub-Folder Recursively
    ForEach($SubFolder in $SubFolders)
    {
        #Exclude "Forms" and Hidden folders
        If(($SubFolder.Name -ne "Forms") -and (-Not($SubFolder.Name.StartsWith("_"))) -and $SubFolder.Name -ne $RootFolder.Name)
        {
            #Call the function recursively
            Delete-SPOEmptyFolders $SubFolder
        }
    }
 
    #Get All Files and Sub-Folders from the Sub-folder
    $SubFolders = $Folder.Folders
    $Files = $Folder.Files
    $Ctx.Load($SubFolders)   
    $Ctx.Load($Files)
    $Ctx.ExecuteQuery()
 
    Write-host -f Yellow "Checking if the folder is Empty:" $Folder.serverRelativeURL
    #Delete Empty Folders
    If($SubFolders.Count -eq 0 -and $Files.Count -eq 0)
    {
        #Delete the folder
        $EmptyFolder=$Ctx.web.GetFolderByServerRelativeUrl($Folder.ServerRelativeUrl)
        $EmptyFolder.Recycle() | Out-Null
        $Ctx.ExecuteQuery()
        Write-host -f Green "`tDeleted Empty Folder:"$Folder.ServerRelativeUrl 
    }
}
 
#Set Variables
$SiteURL = "<SiteURL>"
$LibraryName = "documents"
 
#Get Credentials to connect
$Cred = Get-Credential
  
Try {
    #Setup the context
    $Ctx = New-Object Microsoft.SharePoint.Client.ClientContext($SiteURL)
    $Ctx.Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($Cred.UserName,$Cred.Password)
 
    #Get the Root Folder of the Library
    $List = $Ctx.web.Lists.GetByTitle($LibraryName)
    $RootFolder = $List.RootFolder
    $Ctx.Load($RootFolder)
    $Ctx.ExecuteQuery()
 
    #Call the function to delete empty folders from a document library
    Delete-SPOEmptyFolders $RootFolder
}
catch {
    write-host "Error: $($_.Exception.Message)" -foregroundcolor Red
}

#Read more: https://www.sharepointdiary.com/2018/09/sharepoint-online-delete-empty-folders-using-powershell.html#ixzz6Cxay98oB


###################

#2nd PnP

$siteUrl = "<SiteURL>"
$libraryUrl = "Documents"
$libraryName = "Documents"
 
Connect-PnPOnline -Url $siteUrl -UseWebLogin
$web = Get-PnPWeb
$context = Get-PnPContext
$folder = Get-PnPFolder -RelativeUrl $libraryUrl
$folders_list=@()
 
Function GetAllSubFolders($folder, $context)
{
    $files = $folder.Files
    $context.Load($folder.Files)
    $context.Load($folder.Folders)
    $context.Load($folder.ParentFolder)
    $context.ExecuteQuery()
 
    foreach($subFolder in $folder.Folders)
    {
        GetAllSubFolders $subFolder $context
    }
    
    if ($folder.Files.Count -eq 0 -and $folder.Folders.Count -eq 0 -and (($folder.Name -notmatch 'Document') -and ($folder.Name -notmatch $libraryName )))
    {
        $path = $folder.ParentFolder.ServerRelativeUrl.Substring($web.ServerRelativeUrl.Length)    
        Write-Host "Removing folder " $folder.ServerRelativeUrl.Substring($web.ServerRelativeUrl.Length)   
        #Remove-PnPFolder -Folder $path -Name $folder.Name -Recycle -Force
        $folders_list += $folder.Name + ", " + $folder.ServerRelativeUrl
    }
 
    return $folders_list
}
cls
Write-Host "Looking for empty folders. Please wait..."
$folders_list = GetAllSubFolders $folder $context
$folders_list > "C:\TempFolder\EmptyFolder.txt"
Write-Host $libraryName 'Complete'
