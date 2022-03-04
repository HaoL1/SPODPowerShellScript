#Import SharePoint Online module
Import-Module Microsoft.Online.SharePoint.Powershell

#Set parameter values
$SiteURL="https://hali3.sharepoint.com/sites/teamtest"
$ListName="Documents"
$RestoredFilesPath="C:\Temp\RestoredFiles.csv"

Function Restore-MSGFilesVersion()
{
  param
    (
        [Parameter(Mandatory=$true)] [string] $SiteURL,
        [Parameter(Mandatory=$true)] [string] $ListName
    )
   
        $Cred= Get-Credential
        $Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($Cred.Username, $Cred.Password)
 
        #Setup the context
        $Ctx = New-Object Microsoft.SharePoint.Client.ClientContext($SiteURL)
        $Ctx.Credentials = $Credentials
         
        #Get all items from the list/library
        $Query = [Microsoft.SharePoint.Client.CamlQuery]::CreateAllItemsQuery()
        $List = $Ctx.Web.Lists.GetByTitle($ListName)
        $Ctx.Load($List)
        $ListItems = $List.GetItems($Query)
        $Ctx.Load($ListItems)
        $Ctx.ExecuteQuery()
       
        #Iterate through each item and restore the previous version

        Foreach($Item in $ListItems)
        {
            Write-Host "====================================" -f White
            Write-Host " "
            Write-Host "Scanning the item"$Item["FileRef"] -f Green
            Write-Host "If you see 'File Not Found' error, it means current item is a folder and please ignore." -f Green
            Write-Host " "

            #Get the file versions
            $File = $Ctx.Web.GetFileByServerRelativeUrl($Item["FileRef"])
            $Ctx.Load($File)
            $Ctx.Load($File.Versions)
            $Ctx.ExecuteQuery()
            

            #Get all the files' version greater than 0.
            If($File.Versions.Count -gt 0)
            {
                #Get all the .msg files and restore its version to 1.0
                If($Item["FileRef"] -like "*.msg" )
                {
                    $File.Versions.RestoreByLabel("1.0")
                    $Ctx.ExecuteQuery()
                    Write-Host "Restored" $Item["FileRef"] "to version 1.0" -f red
                    $File | select ServerRelativeUrl | Export-Csv $RestoredFilesPath -Append
                    
                }
                Else{
                Write-host $Item["FileRef"]"is not .msg files" -f yellow
                }    
            }
            Else
            {
                Write-host "No Versions Available for "$Item["FileRef"] -f Yellow
            }
        }
}
 
#Call the function to restore all the .msg files in the library.
Restore-MSGFilesVersion -SiteURL $SiteURL -ListName $ListName
