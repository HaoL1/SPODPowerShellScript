#Varible
$URL = "<SiteURL>"
$listName = "Documents"

#Connect the Site and list you would like to change the content type.
Connect-PnPOnline -Url $URL
$ListItems= Get-PnPListItem -List $listName 

#Change the content type of all the files except folder into "Document"
foreach ($Item in $ListItems) {
   if ($Item.FileSystemObjectType -ne "Folder"){
    if($Item.ContentType -eq "Folder"){
        Set-PnPListItem -List "Documents" -Id $Item -ContentType "Document"
    }
   }
  }
