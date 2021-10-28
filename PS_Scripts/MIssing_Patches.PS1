$file  = "c:\temp\disks.txt"
$file1 = "c:\temp\temp_disks.txt"
#Get-WmiObject -class win32_volume | select driveletter | Out-File -FilePath $file1
Get-WmiObject -class win32_volume | select driveletter | Format-Table -Auto 'DiskDiveLetter=', DriveLetter | Out-File -filepath $file1
(Get-Content $file1) -replace '              ','DiskDriveLetter=' -replace ':','' | Select-Object -skip 4 | Foreach {$_.TrimEnd()} | Out-File -filepath $file
(Get-Content $file) | Select-Object -SkipLast 2 | Out-File -filepath $file
Remove-Item $file1