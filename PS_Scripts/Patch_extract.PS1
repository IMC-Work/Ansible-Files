$days     = $args[0]
$hostname = $env:COMPUTERNAME
$path = "C:\temp\"+$hostname+"_Installed.csv"
$csv = Import-Csv -Path $path
$today = Get-Date
$Vardaysago = $today.adddays(-$days).ToString('yyyy-MM-dd HH:mm:ss')
$file1 = "C:\temp\"+$hostname+"_Extracted_1.csv"
$all_updates=@()

foreach($line in $csv)
{ 
    $properties = $line | Get-Member -MemberType Properties
    for($i=0; $i -lt $properties.Count;$i++)
    {
        $column = $properties[$i]
        $columnvalue = $line | Select -ExpandProperty $column.Name
       
        If ($column.Name -eq "InstallDate") 
        {
         
            if ($columnvalue -gt $Vardaysago)
            {
             
                $update_entry = [pscustomobject]@{
                Device           = $line.Device
                Server_IP        = $line.Server_IP
                Operating_System = $line.Operating_System
                Status           = $line.Status
                FixNumber        = $line.FixNumber
                Installdate      = $line.InstallDate
                Title            = $line.Title}
                
                $all_updates += $update_entry
            }
        }
    }
}
$all_updates | ConvertTo-Csv -NoTypeInformation | % { $_ -replace '"', "" } | out-file -Force $file1 -en ascii
#
# This code amends the installdate to a blank value for all Applicable Patches
#
$csv = Import-Csv -Path $file1
$file2 = "C:\temp\"+$hostname+"_Extracted_2.csv"
$all_updates=@()

foreach($line in $csv)
{
    $properties = $line | Get-Member -MemberType Properties
    for($i=0; $i -lt $properties.Count;$i++)
    {
        $column = $properties[$i]
        $columnvalue = $line | Select -ExpandProperty $column.Name

        If ($column.Name -eq "Status")
            {  
                if ($line.Status -like "*Applicable*")
                {
                    $date = " "
                    $update_entry = [pscustomobject]@{
                    Device           = $line.Device
                    Server_IP        = $line.Server_IP
                    Operating_System = $line.Operating_System
                    Status           = $line.Status
                    FixNumber        = $line.FixNumber
                    Installdate      = $date
                    Title            = $line.Title}
                
                    $all_updates += $update_entry
                }
                elseif ($line.Status -like "*Installed*")
                {
                    $update_entry = [pscustomobject]@{
                    Device           = $line.Device
                    Server_IP        = $line.Server_IP
                    Operating_System = $line.Operating_System
                    Status           = $line.Status
                    FixNumber        = $line.FixNumber
                    Installdate      = $line.Installdate
                    Title            = $line.Title}
                
                    $all_updates += $update_entry
                }
            }
    }
}

$all_updates | ConvertTo-Csv -NoTypeInformation | % { $_ -replace '"', "" } | out-file -Force $file2 -en ascii
#
# This code removes the patch "Windows Malicious Software Removal Tool x64" from the file
#
$csv = Import-Csv -Path $file2
$file3 = "C:\temp\"+$hostname+"_Extracted_3.csv"
$file4 ="C:\temp\"+$hostname+"_Extracted.csv"
$all_updates=@()

foreach($line in $csv)
{
    $properties = $line | Get-Member -MemberType Properties
    for($i=0; $i -lt $properties.Count;$i++)
    {
        $column = $properties[$i]
        $columnvalue = $line | Select -ExpandProperty $column.Name
       
        If ($column.Name -eq "Title") 
        {
         
            if ($line.Title -like "*Malicious*")
            {
            }
            else
            {
                $update_entry = [pscustomobject]@{
                Device           = $line.Device
                Server_IP        = $line.Server_IP
                Operating_System = $line.Operating_System
                Status           = $line.Status
                FixNumber        = $line.FixNumber
                Installdate      = $line.InstallDate
                Title            = $line.Title}
                
                $all_updates += $update_entry
            }
        }
    }
}

$all_updates | ConvertTo-Csv -NoTypeInformation | % { $_ -replace '"', "" } | out-file -Force $file3 -en ascii
import-csv $file3 |sort installdate -Descending | Export-Csv -Path $file4 -NoTypeInformation
#
# This code removes all the temporary files that have been created during this process
#
$file5  = "C:\temp\"+$hostname+".txt"
$file6  = "C:\temp\"+$hostname+".csv"
$file7  = "C:\temp\scan_results.csv"

$from = Get-Content -Path $file4 | Select-Object -skip 1
Add-Content -Path $file5 -Value $from
import-csv $file5 |sort installdate -Descending | Export-Csv -Path $file6 -NoTypeInformation

Remove-Item -Path $file1
Remove-Item -Path $file2
Remove-Item -Path $file3
Remove-Item -Path $file5
Remove-Item -Path $file7
