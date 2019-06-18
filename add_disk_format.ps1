#change the name of the cd rom drive so that we can utilize "D"
if((get-volume | Where-Object {$_.DriveType -eq "CD-ROM"}).DriveLetter -eq "D"){

    Get-WmiObject -Class Win32_volume -Filter "DriveLetter = 'D:'" |Set-WmiInstance -Arguments @{DriveLetter='Q:'}

}

#grab all un-initialized disks
$disks = get-disk | Where-Object {$_.PartitionStyle -eq "RAW"}
$count = 0

foreach($disk in $disks){

    #create a new letter for each drive using ascii starting with D
    $driveLetter = [char](68+$count)
    
    #initialize the disk, create a partition, format ntfs volume and set lable to "data drive"
    $disk | Initialize-Disk -PartitionStyle MBR -PassThru | New-Partition -DriveLetter $driveLetter -UseMaximumSize | Format-Volume -FileSystem NTFS -NewFileSystemLabel "Data Drive" -Confirm:$false

    $count++
}