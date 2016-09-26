$AuditDBServer = "." # AuditDB server name
$AuditDB = "AuditDB" # AuditDB name
$TraceFileData = "TraceFileData" # Table name that saves trace data
$AuditDBUserName = "username" # Can access AuditDB username, and need to have permission for alter trace on server level
$AuditDBPassword = "password"
$FromDirs = "E:\dir1","E:\dir2","E:\dir3" # Collect trace files from $FromDirs
$SaveFileDir = "D:\ArchivedTraceFiles" # Trace files save to
$MailColumns = "StartTime, LoginName, HostName, ServerName, DatabaseName, ApplicationName, TextData, EventClass" #Set columns for alerts
$MailEventClasses = "102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 116, 117, 118, 128, 129, 130, 131, 132, 133, 134, 135, 136, 152, 153, 170, 171, 172, 173, 174, 175, 176, 177" # Set EventClass for alerts
$Users = "'username'" # Need to save into database
$MailFrom = "from@abc.com" # Mail from
$MailTo = "to@def.com" # Rcpt To
$MailServer = "smtp.server" # Mail server

$FromDirs | Foreach-Object {
	Get-ChildItem $_ -Filter *.trc | Foreach-Object {
		
		try { 
			[IO.File]::OpenWrite($_.FullName).close() # Test file can Be processed

			If( -Not (Test-Path ("$SaveFileDir\" + ('{0:yyyy-MM-dd}' -f (get-childitem $_.FullName).creationtime)))) {
				New-Item -Path "$SaveFileDir" -name "$('{0:yyyy-MM-dd}' -f (get-childitem $_.FullName).creationtime)" -type Directory
			}

			$sql = " select * FROM fn_trace_gettable(N'" + $_.FullName + "', 1)"
			$outfile = "$SaveFileDir\" + ('{0:yyyy-MM-dd}' -f (get-childitem $_.FullName).creationtime) + "\" + (get-date -UFormat %s) + ".csv"

			& bcp "$($sql)" queryout "$outfile" -c -t"\t" -r"|" -S $AuditDBServer -U $AuditDBUserName -P $AuditDBPassword

			$sql = "insert into " + $TraceFileData + " select *  FROM fn_trace_gettable(N'" + $_.FullName + "', 1) where LoginName in (" + $Users + ")" # Only $Users activities will be into database
		    	$output = & sqlcmd -S $AuditDBServer -U $AuditDBUserName -P $AuditDBPassword -Q "$($sql)" -d $AuditDB 		


			$sql = "execute savetableashtml @DBFetch='select " + $MailColumns + " FROM fn_trace_gettable(N^" + $_.FullName + "^, 1)', @DBWhere='EventClass in (" + $MailEventClasses + ")', @DBThere='StartTime'"
			$output = & sqlcmd -S $AuditDBServer -U $AuditDBUserName -P $AuditDBPassword -Q "$($sql)" -d $AuditDB				
				
			if ($output -like "*<table*") {
				Send-MailMessage -To $MailTo -From $MailFrom -Subject "資料庫特權活動即時告警" -Body "$output" -BodyAsHtml -SmtpServer $MailServer -Encoding ([System.Text.Encoding]::UTF8)		
			} 

        		Remove-Item $_.FullName
		}
		catch {}

	}
}
