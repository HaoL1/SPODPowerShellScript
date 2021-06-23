Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\16\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"
  
Function Download-SPOFolder()
{
    param
    (
        [Parameter(Mandatory=$true)] [string] $SiteURL,
        [Parameter(Mandatory=$true)] [Microsoft.SharePoint.Client.Folder] $SourceFolder,
        [Parameter(Mandatory=$true)] [string] $TargetFolder
    )
    Try {
          
        #Create Local Folder, if it doesn't exist
        $FolderName = ($SourceFolder.ServerRelativeURL) -replace "/","\"
        $LocalFolder = $TargetFolder + $FolderName
        If (!(Test-Path -Path $LocalFolder)) {
                New-Item -ItemType Directory -Path $LocalFolder | Out-Null
        }
          
        #Get all Files from the folder
        $FilesColl = $SourceFolder.Files
        $Ctx.Load($FilesColl)
        $Ctx.ExecuteQuery()
  
        #Iterate through each file and download
        Foreach($File in $FilesColl)
        {
            $TargetFile = $LocalFolder+"\"+$File.Name
            #Download the file
            $FileInfo = [Microsoft.SharePoint.Client.File]::OpenBinaryDirect($Ctx,$File.ServerRelativeURL)
            $WriteStream = [System.IO.File]::Open($TargetFile,[System.IO.FileMode]::Create)
            $FileInfo.Stream.CopyTo($WriteStream)
            $WriteStream.Close()
            write-host -f Green "Downloaded File:"$TargetFile
        }
          
        #Process Sub Folders
        $SubFolders = $SourceFolder.Folders
        $Ctx.Load($SubFolders)
        $Ctx.ExecuteQuery()
        Foreach($Folder in $SubFolders)
        {
            If($Folder.Name -ne "Forms")
            {
                #Call the function recursively
                Download-SPOFolder -SiteURL $SiteURL -SourceFolder $Folder -TargetFolder $TargetFolder
            }
        }
     }
    Catch {
        write-host -f Red "Error Downloading Folder!" $_.Exception.Message
    }
}
  
#Set parameter values
$SiteURL="<SiteURL>"
$FolderRelativeUrl ="Shared Documents/Reports"
$TargetFolder="C:\Docs"
  
#Setup Credentials to connect
$Cred= Get-Credential
$Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($Cred.Username, $Cred.Password)
  
#Setup the context
$Ctx = New-Object Microsoft.SharePoint.Client.ClientContext($SiteURL)
$Ctx.Credentials = $Credentials
 
#Get the Web
$Web = $Ctx.Web
$Ctx.Load($Web)
$Ctx.ExecuteQuery()
$Web.ServerRelativeUrl+$FolderRelativeUrl
       
#Get the Folder
$SourceFolder = $Web.GetFolderByServerRelativeUrl($Web.ServerRelativeUrl+$FolderRelativeUrl)
$Ctx.Load($SourceFolder)
$Ctx.ExecuteQuery()
 
#Call the function to download Folder
Download-SPOFolder -SiteURL $SiteURL -SourceFolder $SourceFolder -TargetFolder $TargetFolder

#Read more: https://www.sharepointdiary.com/2017/07/download-folder-from-sharepoint-online-using-powershell.html#ixzz6HUeMAUI7
