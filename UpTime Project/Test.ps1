#
# Test.ps1
#
function getLogs($logstartTime, $logEndTime = (Get-Date))
{
    try{
        $logs = Get-WinEvent -MaxEvents 1000 -FilterHashTable `
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
    return $logs
}
$dateForUptime = 6;  #set the number of past days from which the fetching logs should start
$result = New-Object System.Collections.ArrayList;  #To store logs of a day
$result.Clear()

$result = getLogs (Get-Date).AddDays(-7).Date (Get-Date).AddDays(-5).Date
$result