#Set parameter values
$SiteURL="https://hali3.sharepoint.com/sites/teamtest"
$ListName="LargeLibrary"
$RestoredFilesPath="C:\Temp\RestoredFiles.csv"
$CheckFiles="C:\Temp\CheckFiles.csv"

Function Restore-MSGFilesVersion()
{
  param
    (
        [Parameter(Mandatory=$true)] [string] $SiteURL,
        [Parameter(Mandatory=$true)] [string] $ListName
    )
   
      Connect-PnPOnline -Url $SiteURL -UseWebLogin
      $ListItems= Get-PnPListItem -List $ListName -PageSize 1000
      $ctx = Get-PnPContext
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
            $File | select ServerRelativeUrl | Export-Csv $CheckFiles -Append

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

