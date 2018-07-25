@echo off
rem Blame TristanK
rem Finds Bad Things in Sysvol.
rem Warning: Bad Things may include passwords.

Setlocal 
rem get unquoted version of argument
Set TargetDirectory=%~1
Set OutputFileName=%~2

if "%1"=="" goto Usage
if "%2"=="" set OutputFileName=BadStuff.txt

set FindStrCmd=FINDSTR /S /I /N

echo Scanning at %TIME% > "%OutputFileName%"

rem add file extensions you know and love to the list below - XML, SQL, CFG, you name it.

for %%G in (cmd,bat,vbs,ps1,txt,ini) DO (
	echo .
	echo Scanning %%G
	%FindStrCmd% "password" "%TargetDirectory%\*.%%G" >> "%OutputFileName%"
	%FindStrCmd% "pass" "%TargetDirectory%\*.%%G" >> "%OutputFileName%"
	%FindStrCmd% "pwd" "%TargetDirectory%\*.%%G" >> "%OutputFileName%"
	%FindStrCmd% "admin" "%TargetDirectory%\*.%%G" >> "%OutputFileName%"
	echo .)

goto exit

:Usage
echo.
Echo USAGE:
Echo Find-BadStuffInSysVol \\dc01\sysvol BadStuff.txt
echo.

:Exit
Endlocal