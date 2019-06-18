Import-Module activedirectory

function mainFunction{
    
    
    $user  = getUserInformation
    $userEmail = getEmail $user

    #call appropriate function to get the new random password based on type of account
    if($user.substring(($user.length -2) -eq "-a") -or $user.substring(($user.length -2) -eq "-e")){

        $newPassword = create_32_Password

    }elseif($user.substring(($user.length -2) -eq "-o")){

        $newPassword = create_20_Password

    }else{
        
        $newPassword = create_8_Password

    }

    setPassword $user $newPassword
    $passwordConfirmation = passwordChangeConfirm $user

    #check return value from reset check and give appropriate prompt to user
    if($passwordConfirmation -eq $true){
        $name = (Get-ADUser $userName).Name
        Write-Host "The password for $names's $userName account has been reset." -ForegroundColor Green
        sendEmail $userEmail $newPassword $user
    }else{
        Write-Host "Password reset failed." -ForegroundColor red
        Write-Host "Would you like to try again?"
        $answer = Read-Host "Enter (y)es or (n)o"
        $answer.ToLower() 
        if($answer -eq "y" -or $answer -eq "yes"){
            mainFunction
        }elseif($answer -eq "n" -or $anwser -eq "no"){
            $newPassword = $null
            exit
        }else{
            Write-Host "Invalid command. Restarting program." -ForegroundColor Red
            mainFunction  
        }
    }
}

#prompt the administrator for the user information
#and confirm that the information has been entered correctly
function getUserInformation{
    
    cls
    #disclaimer about program
    Write-Host "This app is only for changing passwords by authorized users only!" -ForegroundColor Green
    $userName = Read-Host "Username needing password"

    #validate that the username entered is in the valid format
    if($userName.Length -gt 4){

        #validate the entered username against Active Directory
        $confirm = Get-ADUser -Filter {SamAccountName -eq $userName}
        if($confirm -eq $null){
            Write-Host "$userName does not exist in Active Directory" -ForegroundColor red
            write-host "Try Again?" -ForegroundColor Red
            $continue = read-Host "Enter (y)es or (n)o"
            $continue.ToLower()
            if($continue -eq "y" -or $continue -eq "yes"){
                getUserInformation
            }else{
                exit
            }

        }else{
            
            $name = (Get-ADUser $userName).Name
            $confirm = $confirm.SamAccountName
            
            if($userName -eq $confirm){
            
                #confirm with user one more time that this is the user they want to reset
                Write-Host "Just to confirm..." -ForegroundColor Green
                Write-Host "You're changing: $name's account: $confirm" -ForegroundColor Green
                $answer =( Read-Host "Enter (y)es or (n)o").ToLower() 

                #get the user response and present propper prompt
                if($answer -eq "y" -or $answer -eq "yes"){
                    return $confirm
                }elseif($answer -eq "n" -or $answer -eq "no"){
                    getUserInformation
                }else{
                    Write-Host "Invalid command... Restarting..." -ForegroundColor Red
                    mainFunction
                }
  
            }else{
                #if the username returned from Active Directory do not match present error
                Write-Host "Values returned from AD do not match" -ForegroundColor red
                Write-Host "Value entered: $username" -ForegroundColor red
                Write-Host "Value recieved: $confirm" -ForegroundColor red
                Write-Host "Press enter to continue..." -NoNewline -ForegroundColor red
                $Host.UI.ReadLine()
                getUserInformation
            }
        }
    }else{
            #present error to user if they entered the username in an invalid format
            Write-Host "Invalid Username format. Username was too short" -ForegroundColor Red
            Write-Host "Press enter to continue..." -NoNewline -ForegroundColor red
            $Host.UI.ReadLine()
            getUserInformation
    }
}

#create a new 8 char password
function create_8_Password{

    #declare allowable values
    $lower = "abcdefghijklmnopqrstuvwxyz".ToCharArray()
    $upper = "ABCDEFGHIGJKLMNOPQRSTUVWXYZ".ToCharArray()
    $number = "0123456789".ToCharArray()
    $special ="@#$".ToCharArray()

    $newPass = ""

    #loop through and select random value a group of values
    #based on location % whatever number
    for($i = 0; $i -lt 8; $i++){

        if($i -eq 0){
            $newPass += $upper | Get-Random
        }elseif($i -gt 0 -and $i -lt 6){
            $newPass += $lower | Get-Random
        }elseif($i -eq 7){
            $newPass += $number | Get-Random
        }elseif($i -eq 6){
            $newPass += $special | Get-Random
        }
    }

    #send the new password back to the main function
    return $newPass
}

#create a new 20 char password
function create_20_Password{

    #declare allowable values
    $lower = "abcdefghijklmnopqrstuvwxyz".ToCharArray()
    $upper = "ABCDEFGHIGJKLMNOPQRSTUVWXYZ".ToCharArray()
    $number = "0123456789".ToCharArray()
    $special ="._-#$@:%+=".ToCharArray()

    $newPass = ""

    #loop through and select random value a group of values
    #based on location % whatever number
    for($i = 0; $i -lt 20; $i++){

        if($i -eq 0){
            $newPass += $upper | Get-Random
        }elseif($i % 7 -eq 0){
            $newPass += $special | Get-Random
        }elseif($i % 6 -eq 0){
            $newPass += $number | Get-Random
        }elseif($i % 3 -eq 0){
            $newPass += $upper | Get-Random
        }else{
            $newPass += $lower | Get-Random
        }
    }

    $values = $newPass.ToCharArray()
    $newPass = ""

    for($i = 0; $i -lt 20; $i++){

        $char = $values | Get-Random 

        if($newPass[$i-1] -ne $char){

            $newPass += $char 

        }else{
            $i--
        }
    }

    #send the new password back to the main function
    return $newPass
}


#creates a new 32 character password
function create_32_Password{

    #declare allowable values
    $lower = "abcdefghijklmnopqrstuvwxyz".ToCharArray()
    $upper = "ABCDEFGHIGJKLMNOPQRSTUVWXYZ".ToCharArray()
    $number = "0123456789".ToCharArray()
    $special ="#$%".ToCharArray()

    $newPass = ""

    #loop through and select random value a group of values
    #based on location % whatever number
    for($i = 0; $i -lt 32; $i++){

        if($i -eq 0){
            $newPass += $upper | Get-Random
        }elseif($i % 7 -eq 0){
            $newPass += $special | Get-Random
        }elseif($i % 6 -eq 0){
            $newPass += $number | Get-Random
        }elseif($i % 3 -eq 0){
            $newPass += $upper | Get-Random
        }else{
            $newPass += $lower | Get-Random
        }
    }

    $values = $newPass.ToCharArray()
    $newPass = ""

    for($i = 0; $i -lt 32; $i++){
        
        $char = $values | Get-Random 

        if($newPass[$i-1] -ne $char){

            $newPass += $char 

        }else{
            $i--
        }
    }

    #send the new password back to the main function
    return $newPass
}

#sets the new password in the user's DB row
function setPassword{

    Param([string]$user,[string]$newPassword)

    #using Active Directory module commands, reset the password and unlock the account of the user
    $description = get-aduser -Identity $user -Properties * | select Description
    if($description.description.IndexOf("- Disabled") -ne -1){
        $description = $description.Substring(0, $description.IndexOf("- Disabled"))
    }else{
        $description = $description.Description
    }

    Set-ADUser -Identity $user -Replace @{description=$description} -ChangePasswordAtLogon:$true 
    Unlock-ADAccount -Identity $user 
    Enable-ADAccount -Identity $user 
    Set-ADAccountPassword -Identity $user -Reset -NewPassword (ConvertTo-SecureString -AsPlainText $newPassword -Force) 

}

#get the user's email address
function getEmail{

    param([string]$userName)

    #convert the username from the Admin level username to a regular account username
    if($userName.substring(($userName.length -2))-eq "-a" -or $userName.substring(($userName.length -2))-eq "-e" -or $userName.substring(($userName.length -2))-eq "-o"){
          $regularAccount = $userName.substring(0,($userName.length -2))
    }else{
        $regularAccount = $userName
    }
    #get the regular account email address
    $email = (get-aduser $regularAccount -Properties *).EmailAddress

    return $email

}

#sends a $secure email to the user with their new password
function sendEmail{

    param([string]$email,[string]$pw,[string]$userName)
    
    #create variables for email using the email and password passed in from the main function
    $to = $email
    $from = #TODO add the email you wish to be sent from 
    $subject = '$secure Your user account'
    $body = 
"Your password for your $userName account has been reset to:
   
$pw

Please login to with your $userName account using the password provided above and you will be prompted  to reset your password.


Thanks,
Windows Server Admin Team"
    
    #sent the email using the defined SMTP server
    #TODO add your SMTP server
    Send-MailMessage -SmtpServer  -To $to -From $from -Subject $subject -Body $body

    #let the user know that an email has been sent to the proper email address
    write-host "A secure email has been sent to $email with their new password" -ForegroundColor Green

}

#confirm that the password has been changed
function passwordChangeConfirm{

    param([string]$userName)
    
    #get the date and time that the password was last reset
    $resetDate = (get-aduser $userName -Properties *).PasswordLastSet

    #get the current date and time minus 5 minutes
    $currentDate = (get-date).AddMinutes(-5)

    #confirm that the updated time is after the current time minus 5 minutes
    if($resetDate -gt $currentDate){
        return $true
    }else{
        return $false
    }

}

#call main function to start program
mainFunction

#set password varible to NULL so that it is not stored in RAM
$newPassword = $null