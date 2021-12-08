$hostname  = $env:COMPUTERNAME
$file1     = "C:\temp\"+$hostname+"_Installed.csv"
$file2     = "C:\temp\"+$hostname+"_Applicable.csv"
$file3     = "C:\temp\"+$hostname+"_Extracted.csv"
$file4     = "C:\temp\"+$hostname+".txt"
$file5     = "C:\temp\"+$hostname+".csv"
$file6     = "C:\temp\missing_patches.txt"
$file7     = "C:\temp\patch_filtered_updates.txt"
$file8     = "C:\temp\patch_updates.txt"
$file9     = "C:\temp\patch1.txt"
$file10    = "C:\temp\patch2.txt"
$file11    = "C:\temp\scan_results.csv"
$file12    = "C:\temp\temp_"+$hostname+"_Extracted.txt"
$file13    = "C:\temp\"+$hostname+"_Extracted_1.csv"
$file14    = "C:\temp\"+$hostname+"_Extracted_2.csv"
$file15    = "C:\temp\"+$hostname+"_Extracted_3.csv"

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

# Tidy up and delete all the temporary files

Remove-Item -Path $file4
Remove-Item -Path $file6
Remove-Item -Path $file7
Remove-Item -Path $file8
Remove-Item -Path $file9
Remove-Item -Path $file10
Remove-Item -Path $file11
Remove-Item -Path $file12
Remove-Item -Path $file13
Remove-Item -Path $file14
Remove-Item -Path $file15