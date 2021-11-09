$hostname  = $env:COMPUTERNAME
$file1     = "C:\temp\Patch\"+$hostname+"_Installed.csv"
$file2     = "C:\temp\Patch\"+$hostname+"_Applicable.csv"
$file3     = "C:\temp\Patch\"+$hostname+"_Extracted.csv"
$file4     = "C:\temp\Patch\"+$hostname+".txt"
$file5     = "C:\temp\Patch\"+$hostname+".csv"

#copy 1st line of $file to $file3 (Gives me the headers for the file)

Get-Content $file1 -TotalCount 1 > $file4

#copy all of the Applicable Updates to $file4 (apart from 1st line)

$from = Get-Content -Path $file2 | Select-Object -skip 1
Add-Content -Path $file4 -Value $from

#copy all of Extracted Installed Updates to $file4 (apart from 1st line)

$from = Get-Content -Path $file3 | Select-Object -skip 1
Add-Content -Path $file4 -Value $from

# convert TXT file to CSV file

import-csv $file4 |sort -Property @{Expression = "device" ; Descending = $false} | Export-Csv -Path $file5 -NoTypeInformation
Remove-Item -Path $file4