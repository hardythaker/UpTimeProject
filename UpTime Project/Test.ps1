#
# Test.ps1
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
$dateForUptime = 0;  #set the number of past days from which the fetching logs should start
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
#$result[0]
$firstEventDate = $result[0].TimeCreated.Date
#$firstEventDate
#geting the logs for a perticular date
$logsof_firstEventDate = $result | Sort-Object TimeCreated | Where{$_.TimeCreated.Date -eq $firstEventDate}
$logsof_firstEventDate.Id.Count