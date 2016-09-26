$SaveFileDir = "D:\ArchivedTraceFiles"
$7zipPath = "C:\Program Files\7-Zip\7z.exe"

$SaveFileDate = (Get-Date).AddDays(-1)

$DirYear =  "{0:yyyy}" -f $SaveFileDate
$DirMonth = "{0:MM}" -f $SaveFileDate
$SaveFileName = "{0:yyyy-MM-dd}" -f $SaveFileDate

try{	
	If( -Not (Test-Path "$SaveFileDir\$DirYear")) {
		New-Item -Path "$SaveFileDir" -name "$DirYear" -type Directory
	}

	If( -Not (Test-Path "$SaveFileDir\$DirYear\$DirMonth")) {
		New-Item -Path "$SaveFileDir\$DirYear" -name "$DirMonth" -type Directory
	}

	If( -Not (Test-Path "$SaveFileDir\$DirYear\$DirMonth\$SaveFileName.zip")) {

		&$7zipPath a -tzip "$SaveFileDir\$DirYear\$DirMonth\$SaveFileName.zip" "$SaveFileDir\$SaveFileName\*"

		Remove-Item -Recurse -Force "$SaveFileDir\$SaveFileName"
	}
} catch {}	


