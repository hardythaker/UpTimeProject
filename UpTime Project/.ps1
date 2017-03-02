#
function getLogs($logstartTime, $logEndTime = (Get-Date))
{
    try{
        $result = Get-WinEvent -MaxEvents 1000 -FilterHashTable `
        @{
            LogName = "System";
            ID = 6005,6006 ; #42,1 For sleep Time Logs
            ProviderName = "EventLog","Microsoft-Windows-Kernel-General","Microsoft-Windows-Kernel-Power";
            Level=4; #4 = Information
            StartTime = $logstartTime;
			EndTime = $logEndTime
        }`
        -Force -Oldest | Sort-Object TimeCreated -Unique | Select TimeCreated,Id,Message
    }
    catch{
        $ButtonType = [System.Windows.MessageBoxButton]::OK
        $MessageBoxTitle = "Error"
        $Messageboxbody = "No events Found for last 1 month"
        $MessageIcon = [System.Windows.MessageBoxImage]::Information
        [System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$messageicon)
    }
    return $result
}

$dateForUptime = 1;  #set the number of past days from which the fetching logs should start
$result = New-Object System.Collections.ArrayList;  #To store logs of a day
$result.Clear()


Do
{
    $logstartTime = (Get-Date).Date - (New-TimeSpan -Days $dateForUptime) #from which date start fetching logs
    $result = getLogs $logstartTime
    $dateForUptime++
    if($dateForUptime -ge ([DateTime]::DaysInMonth([DateTime]::Now.Year,[DateTime]::Now.Month)))
    {
        $ErrorActionPreference = “Stop” 
    }
}
Until(($result.Count -ne 0) -or ($dateForUptime -gt ([DateTime]::DaysInMonth([DateTime]::Now.Year,[DateTime]::Now.Month))))

$firstEventDate = $result[0].TimeCreated.Date

#geting the logs for a perticular date
$logsof_firstEventDate = $result| Sort-Object TimeCreated | Where{$_.TimeCreated.Date -eq $firstEventDate}
#$logsof_firstEventDate
$shutdown = New-Object System.Collections.ArrayList
$startup = New-Object System.Collections.ArrayList
$overall = New-Object System.TimeSpan
$findFirstLog = New-Object System.Collections.ArrayList
$findLastLog = New-Object System.Collections.ArrayList
for ($i=0 ; $i -lt $logsof_firstEventDate.Length; $i++)
{
	if(($logsof_firstEventDate[0].Id -eq 6006) -and ($i -eq 0))
    {
		$counter = 1
		do{
			$latestDate = $firstEventDate.AddDays(-$counter)
			$latestStartDate = $latestDate.AddDays(1)
			#echo" "
			$findFirstLog.Clear()
			$findFirstLog = getLogs $latestDate $latestStartDate
			#$findFirstLog
			$counter++
			$latest6005 = $findFirstLog |  where{($_.TimeCreated.Date -eq $latestDate)} | where{$_.Id -eq 6005} | select-object -Last 1
			#$latest6005
		}
		until(($latest6005.Id -eq 6005) -or ($counter -gt 99))
		$startup += $latest6005.TimeCreated
	}
    elseif($logsof_firstEventDate[$i].Id -eq 6005)
    {
        $startup += $logsof_firstEventDate[$i].TimeCreated;
    }
}

 #insert shutdown time
for($i=($logsof_firstEventDate.Length)-1;$i -ge 0 ; $i--)
{
    #on a perticular date if the last event is of startup, then Consider that system was on till the mid-night 11:59:59pm of that date
    if($logsof_firstEventDate[($logsof_firstEventDate.Length)-1].Id -eq 6005 -and $i -eq (($logsof_firstEventDate.Length)-1))
    {
		do{
			$upComingStartDate = $firstEventDate.Date.AddDays(1)
			$upComingEndDate = $firstEventDate.Date.AddDays(2)
			#changes have to be done coz this will forcefully take now time. if today only shutdown event is happened we have to consider that also
			if($upComingStartDate -eq (Get-Date).Date)
			{
				#$TimeCreated = Get-Date
				$last6006 = Get-Date
				$shutdown += $last6006
			}
			else
			{
				$last6006 = $result | where{($_.TimeCreated -ge $upComingStartDate) -and ($_.TimeCreated -le $upComingDate) } | where{$_.Id -eq 6006} | Select-Object -First 1
			}
			$upComingDate_Counter++
		}until(($last6006.ID -eq 6006) -or ($upComingStartDate -eq (Get-Date).Date))
		$shutdown += $last6006.TimeCreated
    }
    elseif($logsof_firstEventDate[$i].Id -eq 6006)
    {
        $shutdown += ($logsof_firstEventDate[$i].TimeCreated);
    }
}


$startup+"Start"
echo " "
$shutdown+"OFF"


