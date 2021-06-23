#Add references to SharePoint client assemblies and authenticate to Office 365 site – required for CSOM
$packagesPath = "C:\Program Files\WindowsPowerShell\Modules\SharePointPnPPowerShellOnline\3.13.1909.0"
Add-Type -Path ($packagesPath + "/Microsoft.SharePoint.Client.dll")
Add-Type -Path ($packagesPath + "/Microsoft.SharePoint.Client.Runtime.dll")
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12;
$userName = Read-Host -Prompt 'Enter your email address' 
$pwd = Read-Host -Prompt 'Enter your password' -AsSecureString
$SiteURL = "https://<tenant>.sharepoint.com/sites/teamtest"
$context = New-Object Microsoft.SharePoint.Client.ClientContext($SiteURL)
$context.Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($userName, $pwd)

$web = $context.Web;
$list = $web.Lists.GetByTitle("Documents")
$files = $list.GetCheckedOutFiles()
$user = $web.CurrentUser;
$context.Load($list);
$context.Load($user);
$context.Load($files);
$context.ExecuteQuery();

foreach($file in $files)
{
    
    if($file.CheckedOutById -ne $user.Id){
    try{
        $file.TakeOverCheckOut()
        $context.ExecuteQuery()
        $fileUrl = [string]::Concat($list.ParentWebUrl, $file.ServerRelativePath.DecodedUrl.Replace($list.ParentWebUrl, ""))
        $newFile = $web.GetFileByServerRelativeUrl($fileUrl)
        $newFile.Checkin("", 1)
        $context.ExecuteQuery()
        Write-Host -f Green "Check in successfully" $fileUrl
       }Catch{Write-Host "Check in failed with" $fileUrl}
        
    }
} 
Write-Host "All the process is finished"
