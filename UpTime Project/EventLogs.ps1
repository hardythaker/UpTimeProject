#
# EventLogs.ps1
#
Clear
#PowerShell.exe -windowstyle hidden `
#{
    add-type -AssemblyName PresentationCore,PresentationFramework
    $ErrorActionPreference = "SilentlyContinue"
    
    #this fn will fetch the logs
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

    $dateForUptime = 4 #set the number of past days from which the fetching logs should start
    $result = New-Object System.Collections.ArrayList  #To store logs of a day
    $result.Clear() #first make it empty

    <#
	fetching logs of yesterday. 
    #if not found then again try for last 1 Month.
    #(usally will happen on saturday,sunday where script will not able to find yesterdays logs)
    #If logs found inbetween on any date.then that date logs will be calculated as Last Overall Uptime
    #if for last one months, none of the startup,shutdown logs found.....
    #(usally happens with new system or new os installation)
    #then trow a msg popup "No events Found for last 1 month"
	#>
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
	
	
	$tempResult = New-Object System.Collections.ArrayList  #To store logs of a day
    $preElement = $null
    foreach($item in $result)
    {
        if($item.Id -eq $preElement)
        {
            Continue
        }
        $tempResult += $item
        $preElement = $item.Id
    }
    $result.Clear()
    $result = $tempResult
	
	#$result
	$firstEventDate = $result[0].TimeCreated.Date

    #geting the logs for a perticular date
    $logsof_firstEventDate = $result |Sort-Object TimeCreated |Where{$_.TimeCreated.Date -eq $firstEventDate}

    $shutdown = New-Object System.Collections.ArrayList
    $startup = New-Object System.Collections.ArrayList
    $overall = New-Object System.TimeSpan
	$findFirstLog = New-Object System.Collections.ArrayList
    #insert startup time 
    for ($i=0 ; $i -lt $logsof_firstEventDate.Length; $i++)
    {
        #on a perticular date if the first event is of shutdown, then Consider that system was on form the mid-night 12am of that date
        
		if(($logsof_firstEventDate[0].Id -eq 6006) -and ($i -eq 0))
        {
	        $counter = 1
			do{
				$latestDate = $firstEventDate.AddDays(-$counter)
				$latestStartDate = $latestDate.AddDays(1)
				#echo""
				$findFirstLog.clear()
				$findFirstLog = getLogs $latestDate $latestStartDate
				$counter++
				$latest6005 = $findFirstLog |  where{($_.TimeCreated.Date -eq $latestDate)} | where{$_.Id -eq 6005} | select-object -Last 1 | Select-Object TimeCreated
			}until(($latest6005 -ne 6005) -or ($counter -gt 99))
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

	$startup
	echo " "
	$shutdown

    #finding overall uptime of a perticular date/day
    for($i=0;$i -lt $startup.Count; $i++)
    {
        $timeSpan = $shutdown[$startup.Count-($i+1)] - $startup[$i]
        $uptime = "{0:00}d {1:00}h {2:00}m {3:00}s" -f $timeSpan.Days,$timeSpan.Hours,$timeSpan.Minutes,$timeSpan.Seconds;
        $overall += $timeSpan
    }

    $overalluptime = "{0:00}d {1:00}h {2:00}m {3:00}s" -f $overall.Days,$overall.Hours,$overall.Minutes,$overall.Seconds;
    
    try{
        $ButtonType = [System.Windows.MessageBoxButton]::OK
        $MessageBoxTitle = "Conserve Energy"
        #$Messageboxbody = "Your System has been running for " + $overalluptime +" on " + $firstEventDate.ToShortDateString()
        $Messageboxbody = "Your System has been running for " + $overalluptime+". Please remember to turn off your system and monitor at the end of the day"
        
		$MessageIcon = [System.Windows.MessageBoxImage]::Information
        [System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$messageicon)
    }
    Catch{
        $Path = "C:\Log"
        $limit = (Get-Date).AddDays(-10)
        Get-ChildItem -Path $Path -Recurse -Force | Where-Object { !$_.PSIsContainer } | sort CreationTime -Descending | select -Skip 2 | Remove-Item -Force
        Get-ChildItem -Path $path -Recurse -Force | Where-Object { !$_.PSIsContainer -and $_.CreationTime -lt $limit } | Remove-Item -Force
        $logName = "$(get-date -format 'yyyy-MM-dd_HH-mm-ss').txt"
        $fullPath = $Path +"\"+ $logName
        New-Item -path $Path -name $logName -itemtype file
        Add-Content -Path $fullPath -Value $Error[0]
        Break
    }

	function sendMail()
	{
		$Username = "skstpc.edu@gmail.com"
		$Password= "skstpc123@gmail.com"
		$message = new-object Net.Mail.MailMessage
		$message.From = "skstpc.edu@gmail.com"
		$message.To.Add("hardiik.thaker@infosys.com")
		$message.Subject = "subject text here..."
		$message.Body = "Your System was ON for " + $overalluptime +" on " + $firstEventDate.ToShortDateString()
		#$attachment = New-Object Net.Mail.Attachment($attachmentpath);
		#$message.Attachments.Add($attachment);

		$smtp = new-object Net.Mail.SmtpClient("smtp.gmail.com", "587")
		$smtp.EnableSSL = $true
		$smtp.Credentials = New-Object System.Net.NetworkCredential($Username, $Password)
		$smtp.send($message)
		#$attachment.Dispose();
	}

	#sendMail;
#}
