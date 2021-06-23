#1st

#Create credential object
$UserCredential = Get-Credential
#Import the Exchange Online ps session
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
Import-PSSession $Session -DisableNameChecking
####Replace "Teamtest" with your group name
$content=Get-UnifiedGroupLinks -Identity "Teamtest"  -LinkType Members
function append-text { 
    process{ 
    foreach-object {$_ + "@<tenant>.onmicrosoft.com"} 
    } 
    } 
$y = $content.name | append-text
$y | Out-File C:\1.txt
Write-host "Export Group finished"

###################

#2nd

#Connect to AzureAD
Connect-AzureAD -Credential $Cred
#Export all group members
##Replace "Teamtest" with your group name
$group = Get-AzureADGroup -SearchString "Teamtest"
$member= Get-AzureADGroupMember -ObjectId $group.ObjectId
##Replace "C:\1.txt" with your path of created .txt file
$member.UserPrincipalName | Out-File C:\1.txt
echo "Export Group finished"

###################

#3rd Export o365 group related site and owner:

 
#Create credential object
$UserCredential = Get-Credential
#Import the Exchange Online ps session
$Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection
Import-PSSession $Session -DisableNameChecking
$O365Groups=Get-UnifiedGroup
$results=@()
foreach ($O365Group in $O365Groups) 
        { 
            $O365GroupSharePointSiteUrl=(Get-UnifiedGroup -Identity $O365Group.Identity).SharePointSiteUrl     
            $SiteOwnerName=(Get-UnifiedGroupLinks –Identity $O365Group.Identity -linktype owners).Name
            Write-Host
        $details = @{  
                
                SiteOwnerName                  = $SiteOwnerName          
                O365GroupSharePointSiteUrl     = $O365GroupSharePointSiteUrl                
                
        }                           
        $results += New-Object -TypeName PSObject -Property $details 
        Write-Host ("Running")
        } 
 
Write-Host ("finish")
$results | export-csv -Path C:\test.csv -NoTypeInformation




