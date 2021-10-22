#Config Parameters

$AdminSiteURL="https://hali3-admin.sharepoint.com"

$ReportOutput="C:\Temp\Reken\SPOStorage.csv"


#Get Credentials to connect to SharePoint Admin Center

$Cred = Get-Credential

 

#Connect to SharePoint Online Admin Center

Connect-SPOService -Url $AdminSiteURL -Credential $Cred

 

#Get all Site collections

$SiteCollections = Get-SPOSite -Limit All

Write-Host "Total Number of Site collections Found:"$SiteCollections.count -f Yellow

 

#Array to store Result

$ResultSet = @()

 
#Total Storage Quota of all sites
$totalstorgaeQuota= 0

Foreach($Site in $SiteCollections)

{

    Write-Host "Processing Site Collection :"$Site.URL -f Yellow

    #Send the Result to CSV

    $Result = new-object PSObject

    $Result| add-member -membertype NoteProperty -name "SiteURL" -Value $Site.URL

    $Result | add-member -membertype NoteProperty -name "Allocated" -Value $Site.StorageQuota

    $Result | add-member -membertype NoteProperty -name "Used" -Value $Site.StorageUsageCurrent

    $Result | add-member -membertype NoteProperty -name "Warning Level" -Value  $site.StorageQuotaWarningLevel

    $ResultSet += $Result

    $totalstorgaeQuota += $Site.StorageUsageCurrent

}

 

#Export Result to csv file

$ResultSet |  Export-Csv $ReportOutput -notypeinformation


Write-Host "Site Quota Report Generated Successfully!" -f Green

#Set the total storage as TB.
$TBTotalStorageQuota = $totalstorgaeQuota/(1024*1024)

Write-Host "The totall storage is" $TBTotalStorageQuota "TB" 
