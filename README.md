# SQLServerTraceFileParser
Parse SQL Server Trace Files and Build Simple Alert System for Audit

## Prerequisite
* SQL Server 2008 R2 or SQL Server 2012
* Powershell
* Permissions

## How to use
1. Build Database `$AuditDB`.
2. Build Table `$TraceFileData` in `$AuditDB` by using `TraceFileData.sql`.
3. Set up arguments in `TraceFileParser.ps1`.
4. Run and Test.

## To-Do
1. Alert mail content need to be html for clearifing output.
