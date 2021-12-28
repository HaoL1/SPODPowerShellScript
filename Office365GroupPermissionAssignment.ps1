Import-Module AzureAd -ErrorAction SilentlyContinue
Import-Module ExchangeOnlineManagement

#Parameters
$CSVFile = "C:\Temp\GroupMemberships.csv"

#User used as reference
$SourceUserAccount = 'test1@hali3.onmicrosoft.com'
#The actual user that needs to be added to Groups
$TargetUserAccount = 'test6@hali3.onmicrosoft.com'

#Credential
$cred=Get-Credential

#Connect to Azure AD
Connect-AzureAD -Credential $cred 
Connect-ExchangeOnline -Credential $cred
 
#Get the User
$SourceUser = Get-AzureADUser -ObjectId $SourceUserAccount
$TargetUser = Get-AzureADUser -ObjectId $TargetUserAccount

#Add Group Members permission from source user to target user
If($SourceUser -ne $Null -and $TargetUser -ne $Null)
{
    #Get All memberships of the Source user
    $SourceMemberships = Get-AzureADUserMembership -ObjectId $SourceUser.ObjectId | Where-object { $_.ObjectType -eq "Group" }
 
    #Loop through Each Group
    ForEach($Membership in $SourceMemberships)
    {
        #Check if the user is not part of the group
        $GroupMembers = (Get-AzureADGroupMember -ObjectId $Membership.Objectid).UserPrincipalName
        If ($GroupMembers -notcontains $TargetUserAccount)
        {
            #Add Target user to the Source User's group
            Add-AzureADGroupMember -ObjectId $Membership.ObjectId -RefObjectId $TargetUser.ObjectId
            Write-host -f Cyan "Added user to Group Members:" $Membership.DisplayName
        }
        Else{
        Write-Host -f Cyan $TargetUserAccount "is already the member of:" $Membership.DisplayName
        }
    }
}
Else
{
    Write-host -f red "Source or Target user is invalid!" -f Yellow
}

#Add Group Owners permission from source user to target user.

If($SourceUser -ne $Null -and $TargetUser -ne $Null)
{
    #Get All Groups where the Source user is a Owner
    $SourceOwnerships = Get-AzureADUserOwnedObject -ObjectId $SourceUser.ObjectId | Where-object { $_.ObjectType -eq "Group" }
 
    #Loop through Each Group
    ForEach($Ownership in $SourceOwnerships)
    {
        #Check if the user is not part of the group
        $GroupOwners = (Get-AzureADGroupOwner -ObjectId $Ownership.Objectid).UserPrincipalName
        If ($GroupOwners -notcontains $TargetUserAccount)
        {
            #Add Target user to the Source User's group
            Add-AzureADGroupOwner -ObjectId $Ownership.ObjectId -RefObjectId $TargetUser.ObjectId
            Write-host -f Cyan "Added user to Group Owners:" $Ownership.DisplayName
        }
        Else{
        Write-Host -f Cyan $TargetUserAccount "is already the owner of:" $Ownership.DisplayName
        }
    }
}
Else
{
    Write-host -f red "Source or Target user is invalid!" -f Yellow
}

#Get User's Group Memberships and Ownerships
$Memberships = Get-AzureADUserMembership -ObjectId $SourceUser.ObjectId | Where-object { $_.ObjectType -eq "Group" }
$Ownerships = Get-AzureADUserOwnedObject -ObjectId $SourceUser.ObjectId | Where-object { $_.ObjectType -eq "Group" }

#Export Office 365 group and related SharePoint sites to a CSV
$Office365Group=[System.Collections.ArrayList]@()

Write-Host -f yellow "Generating the counts of Office 365 groups, which" $SourceUserAccount "has memeberships and ownerships"

for($i=0;$i -lt $Memberships.Count; $i++)
{
    $Office365Group.Add((Get-UnifiedGroup -Identity $Memberships.objectId[$i]))
}

#Set a null value between memberships and ownerships output
$Office365Group.add(@())

for($i=0;$i -lt $Ownerships.Count; $i++)
{
    $Office365Group.Add((Get-UnifiedGroup -Identity $Ownerships.objectId[$i]))
}
    
$Office365Group | select DisplayName, PrimarySmtpAddress, ExternalDirectoryObjectId, SharePointSiteURL | Export-Csv -LiteralPath $CSVFile -NoTypeInformation    



