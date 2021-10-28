$directory  = "C:\Temp\WSUS\Merge"
$mergedfile = "C:\Temp\WSUS\MergedData.csv"
$zippedfile = "C:\Temp\WSUS\MergedData.zip"
$renamedzip = "C:\Temp\WSUS\Archive\MergedData"+[datetime]::Now.Tostring("yyyyMMdd-HHmmss")+".zip"
$archivedir = "C:\Temp\WSUS\Archive"
#
#  Delete c:\temp\mergeddata.zip file if it exists
#
if (Test-Path $zippedfile)
{
   Remove-Item -Path $zippedfile
}
#
#  Merge all the files in c:\temp\merge folder into 1 big file
#
(Get-ChildItem -Path $directory -Filter *.csv).FullName | Import-Csv |Export-Csv $mergedfile -NoTypeInformation
#
#  create a zip file of all the merged data - to be sent to the SFS Server (static name to copy to SFS Server)
#
Compress-Archive -Path $mergedfile -DestinationPath $zippedfile
#
#  rename the zip file to add YYYYMMDD and copy to Archive folder
#
if (!(test-path $archivedir))
{
  New-Item -Path $archivedir -ItemType Directory
}
Copy-Item -Path $zippedfile -Destination $renamedzip
#
#  now need to delete all the old CSV files in C:\Temp\Merge
#
Remove-Item -Path $directory\*.csv
Remove-Item -Path C:\temp\WSUS\MergedData.csv