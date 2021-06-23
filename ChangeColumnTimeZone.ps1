#1.If you want to change the time zone when add new item.

 
#Please replace the below variables with yours.
#region Variables 
$Username = "xxxxx@xxx.onmicrosoft.com"
$Password = "xxxxxxxxxxxxxxxxxxxxxxxxx" 
$siteURL = "https://mymailunisaedu.sharepoint.com/sites/..." 
#endregion Variables
 
#region Credentials 
[SecureString]$SecurePass = ConvertTo-SecureString $Password -AsPlainText -Force 
[System.Management.Automation.PSCredential]$PSCredentials = New-Object System.Management.Automation.PSCredential($Username, $SecurePass) 
#endregion Credentials
 
Connect-PnPOnline -Url $siteURL -Credentials $PSCredentials
 
#The list name “test 10/24 4” is one of my test list when I run the script. Please replace the name of your list 
$listName="test 10/24 4"
$fieldName="Start"
$newFormula="=NOW()+(17.5/24)"
 
$field = Get-PnPField -List $listName -Identity $fieldName
[xml]$schemaXml=$field.SchemaXml
$schemaXml.Field.DefaultFormula=$newFormula
Set-PnPField -List $listName -Identity $fieldName -Values @{SchemaXml=$schemaXml.OuterXml}
Write-Host "Script complete"


###################

 
#2.If you want to change the time value shows in the “start column” of all the existed items (which won’t change by the scripts above).
 
#Please replace the below variables with yours.
#region Variables 
$Username = "xxxxx@xxx.onmicrosoft.com"
$Password = "xxxxxxxxxxxxxxxxxxxxxxxxx" 
$siteURL = "https://mymailunisaedu.sharepoint.com/sites/..." 
#endregion Variables
 
#region Credentials 
[SecureString]$SecurePass = ConvertTo-SecureString $Password -AsPlainText -Force 
[System.Management.Automation.PSCredential]$PSCredentials = New-Object System.Management.Automation.PSCredential($Username, $SecurePass) 
#endregion Credentials
 
Connect-PnPOnline -Url $siteURL -Credentials $PSCredentials
 
#Please replace “timeZoneDifference” with for exmple“+1” when the existed items are set in UTC+9:30 while now you are in UTC+10:30 and so on. 
$listName="test 10/24 4"
$fieldName="Start"
$timeZoneDifference=-1
 
$items=Get-PnPListItem -List $listName
foreach($item in $items){     
      if($item["Start"] -ne $null){
            [datetime]$OldZoneTime=$item["Start"]           
            $targetTime=$OldZoneTime.AddHours($timeZoneDifference)
            Set-PnPListItem -List $listName -Identity $item.Id -Values @{"Start"=$targetTime}
      }     
}
Write-Host "Script complete"
 
Please Note: Now()+(17.5/24) corresponds to UTC +10:30 , Now()+(16.5/24) corresponds to UTC+09:30 , Now()+(15/24) corresponds to UTC +08:00 and son on. So, please switch your setting with different numbers depending on your time zone using.
