Import-Module activedirectory

$day = Read-Host "Enter a number to get a list of users who's passwords expire within that ammount of days or 0 for a list of all users and their expiration dates" 

if($day -eq 0){

    $users = Get-ADUser -filter {Enabled -eq $True -and PasswordNeverExpires -eq $False} –Properties "DisplayName","DistinguishedName","msDS-UserPasswordExpiryTimeComputed" | Select-Object -Property "Displayname","DistinguishedName",@{Name="ExpiryDate";Expression={[datetime]::FromFileTime($_."msDS-UserPasswordExpiryTimeComputed")}}

}else{
    $expDate = (Get-Date).AddDays($day)
    $expDate = Get-Date $expDate -Format g
    $users = Get-ADUser -filter {Enabled -eq $True -and PasswordNeverExpires -eq $False} –Properties "DisplayName","DistinguishedName","msDS-UserPasswordExpiryTimeComputed" | Select-Object -Property "Displayname","DistinguishedName",@{Name="ExpiryDate";Expression={[datetime]::FromFileTime($_."msDS-UserPasswordExpiryTimeComputed")}}
    $users = $users | Where-Object {$_.ExpiryDate -lt $expDate}
}

$userInfo = @()
foreach($user in $users){

    $name = $user.Displayname
    $passDate = $user.ExpiryDate
    $ou = ($user.distinguishedname -split ",")[1].substring(3)

    $object = New-Object -TypeName PSObject
    $object | Add-Member -Name 'Name' -MemberType Noteproperty -Value $name
    $object | Add-Member -Name 'Password Expiration Date' -MemberType NoteProperty -Value $passDate
    $object | Add-Member -Name 'OU' -MemberType Noteproperty -Value $ou

    $userInfo += $object
}

#TODO add your specific paths to the paths below
if($day -gt 0){
    $path = "password_experation\expires_within_" + $day + "_days.csv"
    $userInfo | Export-Csv -Path $path -NoTypeInformation
    Write-Host "All information was written to the file: $path"
}else{
    $userInfo | Export-Csv -Path "password_experation\all_users_expire.csv" -NoTypeInformation
    Write-Host "All information was written to the file: password_experation\all_users_expire.csv"
}