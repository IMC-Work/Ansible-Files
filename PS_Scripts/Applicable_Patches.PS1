(Get-Content -path C:\temp\patch_updates.txt -Raw) -replace ', ', "`r`n" -replace '"','' -replace ']}}', "`r`n" -replace '\[','' -replace ']','' | out-file C:\temp\patch1.txt
(Get-Content -path C:\temp\patch_filtered_updates.txt -Raw) -replace ', ', "`r`n" -replace '"','' -replace ']}}', "`r`n" -replace '\[','' -replace ']','' | out-file C:\temp\patch1.txt -Append
$fqdn = [System.Net.DNS]::GetHostByName($env:COMPUTERNAME).Hostname.ToUpper()
$IP = (Test-Connection -Computername $env:COMPUTERNAME -count 1).IPV4Address.IPAddressToString
$OS = (Get-WmiObject win32_OperatingSystem).Caption
$hostname = $env:COMPUTERNAME
$path = "C:\temp\patch1.txt"
$file_data = Get-Content C:\temp\patch1.txt
$file = "C:\temp\patch2.txt"
$file2 = "C:\temp\"+$hostname+"_Applicable.csv"
$all_updates = "Device,Server_IP,Operating_System,Status,FixNunber,InstallDate,Title"
Add-Content -Path $file -Value $all_updates

foreach($line in Get-Content C:\temp\patch1.txt) {
   if ($line -like '*title: *') {
      $title = $line -replace 'title: ',''}
   elseif ($line -like '*kb: *') {
      $KB = $line -replace 'kb: ','KB'
      $all_updates = $fqdn+","+$IP+","+$OS+",Applicable,"+$KB+",,"+$title
      Add-Content -Path $file -Value $all_updates
      }
} 

import-csv $file -Delimiter "," | Export-Csv $file2 -force -NoTypeInformation
