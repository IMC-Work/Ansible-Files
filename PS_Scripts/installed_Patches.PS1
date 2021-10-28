param(
   $hostname = $env:COMPUTERNAME,
   $fqdn = [System.Net.DNS]::GetHostByName($env:COMPUTERNAME).Hostname.ToUpper(),
   $csvfile = "c:\temp\Patch\scan_results.csv",
   $update_type = "all",
   [switch]$include_title,
   $changeid = ""
)

$IP = (Test-Connection -Computername $env:COMPUTERNAME -count 1).IPV4Address.IPAddressToString
$OS = (Get-WmiObject win32_OperatingSystem).Caption

# Deside if reporting at least something is better than nothing on ANY error
# $ErrorActionPreference = "Stop"
Write-Output("Selected updates type: $update_type")
$Session = New-Object -ComObject "Microsoft.Update.Session"
$searcher = $session.CreateUpdateSearcher()
$updates = $searcher.Search("IsHidden=0 and BrowseOnly=0")
Write-Output("Found updates via API, count: $($updates.Updates.Count)")
$all_updates = @()
$today = Get-Date
$scan_time = $today.ToString('yyyy-MM-dd HH:mm:ss')
If ($updates.Updates.Count -gt 0) {
   #Updates are waiting to be installed
   $count = $updates.Updates.Count

   For ($i = 0; $i -lt $count; $i++) {
      #Create object holding update
      $update = $updates.Updates.Item($i)
      $isInstalled = $update.IsInstalled
      $due = ""
      if ($isInstalled -eq 0) {
         $due = "Applicable"
      }
      else {
         $due = "Installed"
	     }
      $categories = $update.categories |  Select-Object -ExpandProperty name
      $classification = $categories[0]
      #        $classification
      if ($update_type -eq 'security') {

         if ($classification -ne 'SecurityUpdates') {
            continue
		       }
      }

      $update_entry       = [pscustomobject]@{
         Device           = $fqdn
         Server_IP        = $IP
         Operating_System = $OS
         Status           = $due
         FixNumber        = "KB" + $($update.KBArticleIDs)
         InstallDate      = $scan_time
         #            CLASSIFICATION = $classification
      }
      if ($include_title -eq $false) {
         $update_entry | Add-Member -Name 'Title' -Type NoteProperty -Value $update.title
      }
      $all_updates += $update_entry
   }
}
#select unic KB entries
$all_updates = $all_updates | Group-Object 'FixNumber' | ForEach-Object { $_.Group | Select-Object * -First 1 }
Write-Output("Found unique updates via API, count: $($all_updates.count)")

$wmi_updates = @()
$wmi = Get-WmiObject -Class "win32_quickfixengineering"
Write-Output("Found updates via WMI, count: $($wmi.count)")
for ($i = 0; $i -lt $wmi.count; $i++) {
   $kb = $wmi[$i].HotFixID
   $found = $false
   if (($wmi[$i].psBase.properties["InstalledOn"].Value).Length -gt 0) {

      $installedOn = [datetime]($wmi[$i].psbase.Properties["InstalledOn"].Value)
   }
   else {

      $installedOn = $today
   }
   for ($j = 0; $j -lt $all_updates.count; $j++) {
      if ($all_updates[$j].FixNumber -eq $kb) {
         if ($null -ne $installedOn) {
            $all_updates[$j].InstallDate = $installedOn.ToString('yyyy-MM-dd HH:mm:ss K')
         }
         else {
            $all_updates[$j].InstallDate = $scan_time
         }
         $found = $true
         break
      }
   }
   if ($found -eq $false) {

      $wmi_update         = [pscustomobject]@{
         Device           = $fqdn
         Server_IP        = $IP
         Operating_System = $OS
         Status           = "Installed"
         FixNumber        = $wmi[$i].HotFixID
         InstallDate      = $installedOn.ToString('yyyy-MM-dd HH:mm:ss K')
         #            CLASSIFICATION = $($wmi[$i].Description) + "s"
      }
      
      if ($include_title -eq $false) {
         $wmi_update | Add-Member -Name 'Title' -Type NoteProperty -Value $wmi[$i].Description
      }
    
      write-host $wmi_update.FixNumber " " $wmi_update.InstallDate

      $wmi_updates += $wmi_update
   }

}
Write-Output("Found updates via WMI which were not found via API, count: $($wmi_updates.count)")

[array]$all_updates += $wmi_updates

Write-Output("Total updates from API and WMI, count: $($all_updates.count)")

#search for update history log entries
$history_updates = @{}
$regex_test = "[\(,\s]?(KB\d+)[\),\s]"
$historyCount = $searcher.GetTotalHistoryCount()
$historyEntries = $searcher.QueryHistory(0, $historyCount)
Write-Output("Total $($historyEntries.count) update history entries found")

for ($i = $historyEntries.count - 1; $i -ge 0 ; $i--) {
    if ($historyEntries[$i].operation -eq 1 -and ($historyEntries[$i].resultcode -eq 1 -or $historyEntries[$i].resultcode -eq 2)) {
        if ($historyEntries[$i].Title -match $regex_test) {
            $KB = $matches[1]
            $entryInstallDate = $historyEntries[$i].Date.ToString('yyyy-MM-dd HH:mm:ss K')
            $entryTitle = $historyEntries[$i].Title

            $update_entry        = [pscustomobject]@{
                Device           = $fqdn
                Server_IP        = $IP
                Operating_System = $OS
                Status           = "Installed"
                FixNumber        = $KB
                InstallDate      = $entryInstallDate
            }
            if ($include_title -eq $false) {
                $update_entry | Add-Member -Name 'Title' -Type NoteProperty -Value $entryTitle
            } 

            if ($history_updates.ContainsKey($KB)) {
                $history_updates.Remove($KB)
            }    
            $history_updates.Add($KB, $update_entry)
        }
    }
    if ($historyEntries[$i].operation -eq 2 -and ($historyEntries[$i].resultcode -eq 1 -or $historyEntries[$i].resultcode -eq 2)) {
        $KB = "remove is N/A"
        if ($historyEntries[$i].Title -match $regex_test) { 
            $KB = $matches[1] 
            if ($history_updates.ContainsKey($KB)) {
                $history_updates.Remove($KB)
            }
        }
    }
}
# 
# Remove already collected update entries

for ($i = 0; $i -lt $all_updates.count; $i++) {
    $kb = $all_updates[$i].FixNumber
    if ($history_updates.ContainsKey($kb)) {
        $all_updates[$i].InstallDate = $history_updates.$kb.InstallDate
           $history_updates.Remove($kb)
    }
}
 

Write-Output("Found updates according to history log but not provided via WMI and API, count: $($history_updates.count)")
if ($history_updates.count -gt 0) {
    $his_updates = @()
    $history_updates.Keys | foreach-object {
        $his_updates += $history_updates.Item($_)
    }
    $all_updates += $his_updates
}

$all_updates = $all_updates | Group-Object 'FixNumber' | ForEach-Object { $_.Group | Select-Object * -First 1 }
$all_updates | ForEach-Object { $_ | Add-Member -Name 'Title' -Type NoteProperty -Value $changeid }
Write-Output("Total de-duplicated updates from API and WMI, count: $($all_updates.count)")

$all_updates | ConvertTo-Csv -NoTypeInformation  -delimiter ',' | % { $_ -replace '"', "" } | out-file -Force $csvfile -en ascii

$FileName ='imc_scan_results.csv'
$hostname = $env:COMPUTERNAME
$OldCode = $env:COMPUTERNAME
$NewCode = (gwmi win32_bios).SerialNumber 

Copy-Item -Path "C:\Temp\Patch\$Filename" -Destination "C:\Temp\Patch\$hostname.csv"