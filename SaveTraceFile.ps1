$AuditDBServer = "."
$AuditDB = "AuditDB"
$TraceFileData = "TraceFileData"
$AuditDBUserName = "username"
$AuditDBPassword = "password"
$SaveFileDir = "D:\ArchivedTraceFiles"
$BatchSize = 10000
$7zipPath = "C:\Program Files\7-Zip\7z.exe"

$SaveFileDate = (Get-Date).AddDays(-2)

$DirYear =  "{0:yyyy}" -f $SaveFileDate
$DirMonth = "{0:MM}" -f $SaveFileDate
$SaveFileName = "{0:yyyy-MM-dd}" -f $SaveFileDate

try{

	$sql = "select * from " + $AuditDB + ".dbo." + $TraceFileData + " where StartTime < '" + ("{0:yyyy-MM-dd}" -f $SaveFileDate.AddDays(1)) + "'"

	& bcp "$($sql)" queryout "$SaveFileDir\$SaveFileName.csv" -c -t"\t" -r"|" -S $AuditDBServer -U $AuditDBUserName -P $AuditDBPassword

	If( -Not (Test-Path "$SaveFileDir\$DirYear")) {
		New-Item -Path "$SaveFileDir" -name "$DirYear" -type Directory
	}

	If( -Not (Test-Path "$SaveFileDir\$DirYear\$DirMonth")) {
		New-Item -Path "$SaveFileDir\$DirYear" -name "$DirMonth" -type Directory
	}

	If( -Not (Test-Path "$SaveFileDir\$DirYear\$DirMonth\$SaveFileName.zip")) {

		&$7zipPath a -tzip "$SaveFileDir\$DirYear\$DirMonth\$SaveFileName.zip" "$SaveFileDir\$SaveFileName.csv"

		$sql = "select 'starting'; while @@ROWCOUNT <> 0 delete TOP (" + $BatchSize + ") from " + $AuditDB + ".dbo." + $TraceFileData + " where StartTime < '" + ("{0:yyyy-MM-dd}" -f $SaveFileDate.AddDays(1)) + "'"

		& sqlcmd -S $AuditDBServer -U $AuditDBUserName -P $AuditDBPassword -Q "$($sql)" -d $AuditDB

		Remove-Item "$SaveFileDir\$DirYear\$DirMonth\$SaveFileName.csv"
	}
} catch {}	

