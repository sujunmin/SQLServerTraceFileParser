$AuditDBServer = "." # AuditDB server name
$AuditDB = "AuditDB" # AuditDB name
$TraceFileData = "TraceFileData" # Table name that saves trace data
$AuditDBUserName = "username" # Can access AuditDB username, and need to have permission for alter trace on server level
$AuditDBPassword = "password"
$FromDirs = "E:\dir1","E:\dir2","E:\dir3" # Collect trace files from $FromDirs
$ErrorDir = "E:\errdir\" # If errors then save original trace files into $ErrorDir
$MailColumns = "StartTime, LoginName, HostName, ServerName, DatabaseName, ApplicationName, TextData, EventClass" #Set columns for alerts
$MailEventClasses = "102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 116, 117, 118, 128, 129, 130, 131, 132, 133, 134, 135, 136, 152, 153, 170, 171, 172, 173, 174, 175, 176, 177" # Set EventClass for alerts
$MailFrom = "from@abc.com" # Mail from
$MailTo = "to@def.com" # Rcpt To
$MailServer = "smtp.server" # Mail server

$FromDirs | Foreach-Object {
	Get-ChildItem $_ -Filter *.trc | Foreach-Object {
		
		try { 
			[IO.File]::OpenWrite($_.FullName).close() # Test file can Be processed

			$sql = "insert into " + $TraceFileData + " select *  FROM fn_trace_gettable(N'" + $_.FullName + "', 1)"
	    		$output = & sqlcmd -S $AuditDBServer -U $AuditDBUserName -P $AuditDBPassword -Q "$($sql)" -d $AuditDB # Insert trace file data into table
 
			if ($output -like "*個受影響的資料列*") { # Affected Rows in Chinese
				$sql = "select " + $MailColumns + " FROM fn_trace_gettable(N'" + $_.FullName + "', 1) where EventClass in (" + $MailEventClasses + ") order by StartTime"
				$output = & sqlcmd -S $AuditDBServer -U $AuditDBUserName -P $AuditDBPassword -Q "$($sql)" -d $AuditDB # Do some alerts for specified eventclasses				

				if ($output -like "*(0 個受影響的資料列)*") { # No affected rows in Chinese
				} else {
					Send-MailMessage -To $MailTo -From $MailFrom -Subject "資料庫特權活動即時告警" -Body "$output" -SmtpServer $MailServer -Encoding ([System.Text.Encoding]::UTF8)
				}

        			Remove-Item $_.FullName
    			} else {
				$rand = Get-Random
				$newfilename =  $ErrorDir + [string]$rand + ".trc"
				Move-Item -Path $_.FullName -Destination $newfilename
    			}
		}
		catch {}

	}
}
