Import-Module activedirectory
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName PresentationFramework


function mainFunction{
    
    #create the form and get the input
    $return = createForm
    $userName = $return[1]
    
    #make sure user is in AD an username is correct 
    validateUser $userName

    #call function to get the user's email
    $userEmail = getEmail $user

    #call function to get the new random password based on type of account
    if($user.substring(($user.length -2) -eq "-a") -or $user.substring(($user.length -2) -eq "-e")){

        $newPassword = create_32_Password

    }elseif($user.substring(($user.length -2) -eq "-o")){

        $newPassword = create_20_Password

    }else{
        
        $newPassword = create_8_Password

    }
    

     #call function to set the user's password using the new password
    setPassword $userName $newPassword

    #call function to confirm that the password has actually been reset
    $passwordConfirmation = passwordChangeConfirm $user

    #check return value from reset check and give appropriate prompt to user
    if($passwordConfirmation -eq $true){
        sendEmail $userEmail $newPassword $userName
         $ButtonType = [System.Windows.MessageBoxButton]::OK
         $MessageboxTitle = “Success!”
         $name = (Get-ADUser $userName).Name
         $Messageboxbody = "$name's password for their $userName account has been reset! 
A secure email has been sent with their new password"
         $MessageIcon = [System.Windows.MessageBoxImage]::Information
         $result = [System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$messageicon)

    }else{
         $ButtonType = [System.Windows.MessageBoxButton]::YesNo
         $MessageboxTitle = “Error”
         $Messageboxbody = "Password did not successfully update.
Try Again?"
                $MessageIcon = [System.Windows.MessageBoxImage]::Error
                $result = [System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$messageicon)

                if($result -eq "Yes"){
                    mainFunction
                }else{
                    exit
                }
    }

}


function createForm{

    #create the form
    $form = New-Object System.Windows.Forms.Form
    $form.Width = 600
    $form.Height = 200
    $form.BackColor = "white"
    $form.Text = "Admin Password Reset"
    $form.ShowInTaskbar = $true
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen

    #create disclaimer header
    $disclaimer = New-Object System.Windows.Forms.Label
    $disclaimer.Left = 50
    $disclaimer.Top = 15
    $disclaimer.Width = 600
    $disclaimer.ForeColor = "navy"
    $disclaimer.Font =  New-Object System.Drawing.Font("Sans Serif",11,[System.Drawing.FontStyle]::Regular)
    $disclaimer.Text = "This app is for changing passwords by authorized users only!"

    #create the username lable
    $userNameLable = New-Object System.Windows.Forms.Label
    $userNameLable.Left = 50
    $userNameLable.Top = 60
    $userNameLable.Width = 180
    
    $userNameLable.Font = New-Object System.Drawing.Font("Sans Serif",11,[System.Drawing.FontStyle]::Regular)
    $userNameLable.Text = "Username needing reset:"

    #create username input field
    $userName =  New-Object System.Windows.Forms.TextBox
    $userName.Left = 250
    $userName.Top = 60
    $userName.Width = 300
    $userName.Text = ""

    #create the change password button
    $createBtn =  New-Object System.Windows.Forms.Button
    $createBtn.Left = 400
    $createBtn.Top = 90
    $createBtn.Width = 150
    $createBtn.Height = 25
    $createBtn.Text = "Change Password"

    #event handler to close the form after getting values
    $changePassword = [System.EventHandler]{
        $userName.Text
        $form.Close()
    }

    $userName_KeyDown=[System.Windows.Forms.KeyEventHandler]{
 
	    if($_.KeyCode -eq 'Enter')
	    {
           if($userName.TextLength -gt 0){
		        $userName.Text 
           }else{
                $userName.Text = "Enter"
           }
           $form.Close()
	    }

    }

    $userName.add_KeyDown($userName_KeyDown)
    $createBtn.Add_click($changePassword)

    #add everything to the form
    $form.Controls.Add($disclaimer)
    $form.Controls.Add($userNameLable)
    $form.Controls.Add($userName)
    $form.Controls.Add($createBtn)

    #display the form
    $form.ShowDialog()

    return $userName.Text
}

function validateUser{

    Param([string]$userName)

     #validate that the username entered is in the valid format
    if($userName.Length -gt 4){

        #validate the entered username against Active Directory
        $confirm = Get-ADUser -Filter {SamAccountName -eq $userName}
        if($confirm -eq $null){
            
                $ButtonType = [System.Windows.MessageBoxButton]::YesNo
                $MessageboxTitle = “Try again”
                $Messageboxbody = “$userName does not exist in Active Directory
Try again?”
                $MessageIcon = [System.Windows.MessageBoxImage]::Warning
                $result = [System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$messageicon)

                if($result -eq "Yes"){
                    mainFunction
                }elseif($result -eq "No"){
                    exit
                }

        }else{
                $name = (Get-ADUser $userName).Name
                $confirm = $confirm.SamAccountName

            if($userName -eq $confirm){
            
                #confirm with user one more time that this is the user they want to reset
                $ButtonType = [System.Windows.MessageBoxButton]::YesNo
                $MessageboxTitle = “Confirm Change”
                $Messageboxbody = "You want to change the passwrod for $name's account $confirm ?"
                $MessageIcon = [System.Windows.MessageBoxImage]::Question
                $result = [System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$messageicon)

                #get the user response and present propper prompt
                if($result -eq "Yes"){
                    $Global:user = $confirm
                }elseif($result -eq "No"){
                    mainFunction
                }
  
            }else{

                #if the username doesn't exist in AD present prompt
                $ButtonType = [System.Windows.MessageBoxButton]::YesNo
                $MessageboxTitle = “Error”
                $Messageboxbody = "Values returned from AD do not match
Value Entered: $userName
Value returned: $confirm 
Try Again?"
                $MessageIcon = [System.Windows.MessageBoxImage]::Error
                $result = [System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$messageicon)

                if($result -eq "Yes"){
                    mainFunction
                }else{
                    exit
                }
            }
        }
    }elseif($userName.Length -gt 0 -and $userName -ne "Enter"){
                #present error to user if they entered the username in an invalid format
                $ButtonType = [System.Windows.MessageBoxButton]::YesNo
                $MessageboxTitle = “Invalid Format”
                $Messageboxbody = "Invalid username format
Try Again?"
                $MessageIcon = [System.Windows.MessageBoxImage]::Error
                $result = [System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$messageicon)

                if($result -eq "Yes"){
                    mainFunction
                }else{
                    exit
                }
    }elseif($userName -eq "Enter"){
                $ButtonType = [System.Windows.MessageBoxButton]::YesNo
                $MessageboxTitle = “No entry”
                $Messageboxbody = "Did you mean to hit enter?"
                $MessageIcon = [System.Windows.MessageBoxImage]::question
                $result = [System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$messageicon)

                if($result -eq "Yes"){
                     exit
                }else{
                     mainFunction
                }
    }else{
        exit
    }
}

#create a new 8 char password
function create_8_Password{

    #declare allowable values
    $lower = "abcdefghijklmnopqrstuvwxyz".ToCharArray()
    $upper = "ABCDEFGHIGJKLMNOPQRSTUVWXYZ".ToCharArray()
    $number = "0123456789".ToCharArray()
    $special = '@#$'.ToCharArray()

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
    $special ="._-#$@:%+=".ToCharArray()

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

function getEmail{

    param([string]$userName)

    #convert the username from the Admin level username to a regular account username if necessary 
    if($userName.substring(($userName.length -2))-eq "-a" -or $userName.substring(($userName.length -2))-eq "-e" -or $userName.substring(($userName.length -2))-eq "-o"){
          $regularAccount = $userName.substring(0,($userName.length -2))
    }else{
        $regularAccount = $userName
    }
    #get the regular account email address
    $email = (get-aduser $regularAccount -Properties *).EmailAddress

    return $email

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

#sends a $secure email to the user with their new password
function sendEmail{

    param([string]$email,[string]$pw,[string]$userName)
    
    $to = $email
    $from = #TODO add your group email account
    $subject = '$secure Your user account'
    $body = 
"Your $usserName account password has been reset to:
   
$pw

Please login with your $userName account using the password provided above you will prompted to you to reset your password.


Thanks,
Windows Server Admin Team"
    
    #send the email using the defined SMTP server
    #TODO add your smtp server
    Send-MailMessage -SmtpServer  -To $to -From $from -Subject $subject -Body $body

}

function passwordChangeConfirm{

    param([string]$userName)
        
    #confirm that the updated time is after the current time minus 5 minutes

    $resetDate = (get-aduser $userName -Properties *).PasswordLastSet
    $currentDate = (get-date).AddMinutes(-5)

    if($resetDate -gt $currentDate){
        return $true
    }else{
        return $false
    }

}

mainFunction