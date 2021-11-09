$days     = $args[0]
$hostname = $env:COMPUTERNAME
$path = "C:\temp\Patch\$hostname.csv"
$csv = Import-Csv -Path $path
$today = Get-Date
$Vardaysago = $today.adddays(-$days).ToString('yyyy-MM-dd HH:mm:ss')
$file = "C:\temp\Patch\Temp_"+$hostname+"_Extracted.txt"
$file1 = "C:\temp\Patch\"+$hostname+"_Extracted.csv"
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

$all_updates | ConvertTo-Csv -NoTypeInformation | % { $_ -replace '"', "" } | out-file -Force $file -en ascii
#
# This code removes the patch "Windows Malicious Software Removal Tool x64" from the file
#
$csv = Import-Csv -Path $file
$file1 = "C:\temp\Patch\"+$hostname+"_30day_temp.csv"
$file2 ="C:\temp\Patch\"+$hostname+"_30day.csv"
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

$all_updates | ConvertTo-Csv -NoTypeInformation | % { $_ -replace '"', "" } | out-file -Force $file1 -en ascii
import-csv $file1 |sort installdate -Descending | Export-Csv -Path $file2 -NoTypeInformation
remove-item $file
remove-item $file1