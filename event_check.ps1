Import-Module VMware.VimAutomation.Core
Connect-VIServer #server name

#get all events that have happened within the past 60 mins 
$startTime = (Get-Date).AddMinutes(-60)
$events = (Get-VIEvent -Start $startTime -Finish (get-Date))  | Where-Object {$_.fullformattedmessage -notlike "*ramdisk*" -and $_.fullformattedmessage -notlike "User dcui*"}

#declare an array object
$partyInfo = @()

#loop though each event called a party
foreach($party in $events){
    
    if(($party.fullformattedmessage -like "Permission *") -or ($party.fullformattedmessage -like  "Reconfigured *")  -or ($party.fullformattedmessage -like  "*dvPort*down*")  -or ($party.fullformattedmessage -like  "*dvPort*up*") -or ($party.fullformattedmessage -like  "Alarm *") -or ($party.fullformattedmessage -like  "*Power on*") -or ($party.fullformattedmessage -like  "*Power off*") -or ($party.fullformattedmessage -like  "*shutdown") -or ($party.fullformattedmessage -like  "*logged in*") -or ($party.fullformattedmessage -like  "*logged out*") -or ($party.fullformattedmessage -like  "*snapshot*") -or ($party.fullformattedmessage -like  "Deploying *")){

        $executer = $party.UserName
        $hostName  = $party.host.Name 
        $createdTime = $party.CreatedTime 
        $message = $party.FullFormattedMessage

        $object = New-Object -TypeName PSObject
        $object | Add-Member -Name 'Executed by' -MemberType Noteproperty -Value $executer
        $object | Add-Member -Name 'Time Executed' -MemberType Noteproperty -Value $createdTime
        $object | Add-Member -Name 'Executed on' -MemberType Noteproperty -Value $hostName
        $object | Add-Member -Name 'Full event information' -MemberType Noteproperty -Value $message
            
        $partyInfo += $object
    }
}

$now = get-date -format  filedate
$path = #path name + $now +"_vcenter_events.csv"

#write events to csv
$partyInfo | Export-Csv -Path $path -Append -NoTypeInformation

$filesPath = #path name
$files = Get-ChildItem -Path $filesPath | Where-Object {$_.Name -like "*_events*"}

foreach($file in $files){
    if($file.creationtime -lt (get-date).AddDays(-1)){
        $newPath = $filesPath + $file.Name
        move-item -Path $newPath -Destination #path
    }
}

$oldFilesPath = #path
$oldFiles = Get-ChildItem -Path $oldFilesPath | Where-Object {$_.Name -like "*_events*"}

foreach($file in $oldFiles){
    if($file.creationtime -lt (get-date).AddDays(-5)){
           $file | remove-item
    }
}
