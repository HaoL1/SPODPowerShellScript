#Check User License Detail by UPN

param(
    [parameter(Mandatory=$true)][String] $UPN
)
 
#simple check for @ and .
If($UPN -notlike "*@*.*"){
Write-Output ""
$UPN = Read-Host "Missing @ or . Please enter UserPrincipalName"
Write-Output ""
}
 
#get-msoluser into variable
$checkuser =  Get-MsolUser -UserPrincipalName $upn -EA SilentlyContinue 
 
#check for licenses
IF ($checkuser){
    IF (!($checkuser.Licenses)){
        $LicensedUser = $null
        Write-Output ""
        Write-Output "Licenses is null for $($checkuser.UserPrincipalName)"
        Write-Output "IsLicensed is $($checkuser.IsLicensed)"
        Write-Output ""
        }
        Else
        {
        $LicensedUser = $checkuser
        }
      }
      Else
      {
      Write-Error "Get-MsolUser : User Not Found" 
      }
 
#initialize index
[int]$index = 0
 
#get skus and services for user
IF($LicensedUser){
Foreach ($User in $LicensedUser){
    $skus = $user.Licenses.AccountSkuId
    $dname = $User.DisplayName
    $skucount = $skus.count
    Write-Output ""
    Write-Output "-----------$dname has $skucount total sku(s) assignments "
    Write-Output ""
    Write-Output $skus
    Write-Output ""
    Write-Output ""
    
    DO {
            Write-Output ""
            Write-Output "####### License sku service(s) status for $($user.Licenses[$index].AccountSkuId)"
            Write-Output ""
            Write-Output $user.Licenses[$index].ServiceStatus
            $index++
            Write-Output ""
            Write-Output ""
        }until ($index -eq $skucount)
    }
} 


###################

#Check All User Under a License

#1.Get all the license AccountSkuId. Make a note of the AccountSkuId value for the license you want to filter on. (if you cannot connect, please firstly run PowerShell with admin to install the module by Install-Module MSOnline)
 
Connect-MsolService 
Get-MsolAccountSku 

#2. Edit this short script to get the users matching that license. In this case, we’re getting users with the EnterprisePremium license. Replace EnterprisePremium with the AccountSkuID you’re trying to filter by. 
 
Get-MsolUser | Where-Object {($_.licenses).AccountSkuId -match "EnterprisePremium"} 


###################

#Reassign License

#Adjust the script order as below. (You should connect firstly before get all the <AccountSkuId>).
 
#1.Install module
Install-Module MSOnline 
 
#2.Get all the license AccountSkuId 
Connect-MsolService 
Get-MsolAccountSku 
 
#3.Replace the license for user
#replace below yellow part of yours. 
Set-MsolUserLicense -UserPrincipalName "davidchew@contoso.com" -AddLicenses "contoso:DESKLESS" -RemoveLicenses "contoso:ENTERPRISEPACK" 

