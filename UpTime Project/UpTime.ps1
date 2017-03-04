#
# UpTime.ps1
#

add-type -AssemblyName PresentationCore,PresentationFramework
PowerShell.exe -windowstyle hidden `
{
	function getUpTime(){
		$cimString = (Get-WmiObject Win32_OperatingSystem).LastBootUpTime;
		$dateTime= [Management.ManagementDateTimeConverter]::ToDateTime($cimString);
		$timeSpan = (Get-Date) - $dateTime;
		$result = "{0:00}d {1:00}h {2:00}m {3:00}s" -f $timeSpan.Days,$timeSpan.Hours,$timeSpan.Minutes,$timeSpan.Seconds;
		return $result
	}
	function sendMail(){
		$Username = "skstpc.edu@gmail.com"
		$Password= "skstpc123@gmail.com"
		$message = new-object Net.Mail.MailMessage
		$message.From = "skstpc.edu@gmail.com"
		$message.To.Add("hardiik.thaker@infosys.com")
		$message.Subject = "Conserve Energy"
		$message.Body = "Your System has been running for " + $result + ". Please remember to turn off your system and monitor at the end of the day"
		#$attachment = New-Object Net.Mail.Attachment($attachmentpath);
		#$message.Attachments.Add($attachment);

		$smtp = new-object Net.Mail.SmtpClient("smtp.gmail.com", "587")
		$smtp.EnableSSL = $true
		$smtp.Credentials = New-Object System.Net.NetworkCredential($Username, $Password)
		$smtp.send($message)
		#$attachment.Dispose();
	}
	function drawPopupBox($result){
		$ButtonType = [System.Windows.MessageBoxButton]::OK
		$MessageBoxTitle = "Conserve Energy"
		$Messageboxbody = "Your System has been running for " + $result +". Please remember to turn off your system and monitor at the end of the day"
		$MessageIcon = [System.Windows.MessageBoxImage]::Information
		[System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$messageicon)
	}
	
	$result = getUptime;
	if($timeSpan.Days -ge 0)
	{
		drawPopupBox $result
	}
	elif($timeSpan.Days -ge 4)
	{
		sendMail;
	}
}
