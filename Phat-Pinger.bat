@echo off
color 0a
Rem 
Rem Script: 	PHAT PINGER
Rem By:		ahampson
Rem Updated: 	June 2024
Rem
CALL :DrawLogo
Echo[
REM ------------------------------------------ Get/Set Starting Values ------------------------------------------
SET /p targetHost="Enter Target Host :>"
SET /A bufferSize=2
SET /A testCount=0
SET /A increaseValue=1
SET /A bytesSent=0
Set startTime=%time%
ping -n 1 %targetHost% | find "Reply" > .\Pinglog.txt
Echo[
REM ------------------------------------------ PING TEST LOOP ------------------------------------------
:Ping_Test
CALL :DrawLogo
Echo Target Host: %targetHost%
Echo  Ping Count: %testCount%
Echo Buffer size: %bufferSize% Bytes
ping -l %bufferSize% -n 1 %targetHost% | find "Reply" >> .\Pinglog.txt
IF %ERRORLEVEL% == 0 (
	SET /A maxSize= %bufferSize%
	SET /A bufferSize= %bufferSize% + %increaseValue%
	SET /A increaseValue= %increaseValue% + 1
	SET /A testCount= %testCount% + 1
	SET /A bytesSent= %bytesSent% + %bufferSize%
	goto :Ping_Test
)
SET /A bufferSize= %bufferSize% - %increaseValue%
IF %increaseValue% GTR 3 (
	SET /A increaseValue= 0
	goto :Ping_Test
)
Echo[
REM ------------------------------------------ Evaluate 'PING TEST': Packet Response Time------------------------------------------
set endTime=%time%
powershell "&{$time=0; $Count=0; $min=65535; $max=0;get-content .\Pinglog.txt | ForEach-Object{ $_.split() | ForEach-Object{ If($_ -like 'time*'){ If($_ -like '*=*'){ $pingTest = $_.split('=')[1].replace('ms',''); $time += $pingTest; $Count += 1 }ElseIf($_ -like '*<*'){ $pingTest = $_.split('<')[1].replace('ms',''); $time += $pingTest; $Count += 1 }If($pingTest -lt $min){$min = $pingTest}If($pingTest -gt $max){$max = $pingTest} } } }; Write-host \"Min Rx Time: $($min)ms\"; Write-host \"AVG Rx Time: $([MATH]::round($($time/$Count),2))ms\"; Write-host \"Max Rx Time: $($max)ms\"}"
DEL .\Pinglog.txt
echo[
Echo Sent %testCount% sucessful 'Pings' with %bytesSent% Bytes of data.
Echo Test Determined the max buffer size to be %maxSize% Bytes
Echo[
Echo Start Time: %startTime%
Echo End Time: %endTime%
Echo[
REM ------------------------------------------ Evaluate 'PING TEST': Calculate Run Time ------------------------------------------
set options="tokens=1-4 delims=:.,"
for /f %options% %%a in ("%startTime%") do set start_h=%%a&set /a start_m=100%%b %% 100&set /a start_s=100%%c %% 100&set /a start_ms=100%%d %% 100
for /f %options% %%a in ("%endTime%") do set end_h=%%a&set /a end_m=100%%b %% 100&set /a end_s=100%%c %% 100&set /a end_ms=100%%d %% 100

set /a hours=%end_h%-%start_h%
set /a mins=%end_m%-%start_m%
set /a secs=%end_s%-%start_s%
set /a ms=%end_ms%-%start_ms%
if %ms% lss 0 set /a secs = %secs% - 1 & set /a ms = 100%ms%
if %secs% lss 0 set /a mins = %mins% - 1 & set /a secs = 60%secs%
if %mins% lss 0 set /a hours = %hours% - 1 & set /a mins = 60%mins%
if %hours% lss 0 set /a hours = 24%hours%
if 1%ms% lss 100 set ms=0%ms%
set /a totalsecs = %hours%*3600 + %mins%*60 + %secs%
echo Test Run time %hours%:%mins%:%secs%.%ms% (%totalsecs%.%ms%s total)
echo[
REM ------------------------------------------ SPEED TEST LOOP ------------------------------------------
SET /A payload= %maxSize% * 500
Echo Running Speed test with %payload% bytes of data
Set startSpeedTest=%time%
SET /A payloadSize=0
:speedTest
IF %payloadSize% LSS %payload% (
    ping -l %maxSize% -n 1 %targetHost% | find "Reply" > NUL
    IF %ERRORLEVEL% == 0 (
          SET /A payloadSize=%payloadSize% + %maxSize%
          GOTO :speedTest
    ) ELSE (
          IF %maxSize% GEQ 200 (
               Echo "Warning: Packet loss detected! Reducing Buffer Size"
               SET /A maxSize= %maxSize% - 100
               GOTO :speedTest
          )
          Echo WARNING: Speed Test buffer size is too small to continue...
    )
)
ECHO[
ECHO Sent %payloadSize% bytes of data
Set endSpeedTest=%time%
REM ------------------------------------------ Evaluate 'SPEED TEST': Calculate Run Time Performace ------------------------------------------
set options="tokens=1-4 delims=:.,"
for /f %options% %%a in ("%startSpeedTest%") do set start_h=%%a&set /a start_m=100%%b %% 100&set /a start_s=100%%c %% 100&set /a start_ms=100%%d %% 100
for /f %options% %%a in ("%endSpeedTest%") do set end_h=%%a&set /a end_m=100%%b %% 100&set /a end_s=100%%c %% 100&set /a end_ms=100%%d %% 100

set /a hours=%end_h%-%start_h%
set /a mins=%end_m%-%start_m%
set /a secs=%end_s%-%start_s%
set /a ms=%end_ms%-%start_ms%
if %ms% lss 0 set /a secs = %secs% - 1 & set /a ms = 100%ms%
if %secs% lss 0 set /a mins = %mins% - 1 & set /a secs = 60%secs%
if %mins% lss 0 set /a hours = %hours% - 1 & set /a mins = 60%mins%
if %hours% lss 0 set /a hours = 24%hours%
if 1%ms% lss 100 set ms=0%ms%
set /a totalsecs = %hours% * 3600 + %mins% * 60 + %secs%
SET /A speedBPS = %payloadSize% / %totalsecs% / 1000
IF %speedBPS% LEQ 10 (
     Set perf=Poor
     GOTO :AllDone
)
IF %speedBPS% LEQ 100 (
     Set perf=Slow
     GOTO :AllDone
)
IF %speedBPS% LEQ 500 (
     Set perf=Good
     GOTO :AllDone
)
IF %speedBPS% LEQ 1000 (
     Set perf=Fast
     GOTO :AllDone
)
IF %speedBPS% GEQ 1000 (
     Set perf=Ultra
     GOTO :AllDone
)
:AllDone
REM ------------------------------------------ Provide Final Output/Feedback ------------------------------------------
Echo    Speed Test Run time: %hours%:%mins%:%secs%.%ms% (%totalsecs%.%ms%s total)
Echo    Link Transfer Speed: %speedBPS% KBps
Echo    Link/Connection Rating: %perf%
echo[
pause
EXIT
REM ------------------------------------------ LOGO Function ------------------------------------------
:DrawLogo
cls
ECHO " ______  _   _   ___  _____                 "
ECHO " | ___ \| | | | / _ \|_   _|                "
ECHO " | |_/ /| |_| |/ /_\ \ | |                  "
ECHO " |  __/ |  _  ||  _  | | |                  "
ECHO " | |    | | | || | | | | |                  "
ECHO " \_|___ \_|_|_/\_| |_/ \_/__  _____ ______  "
ECHO " | ___ \|_   _|| \ | ||  __ \|  ___|| ___ \ "
ECHO " | |_/ /  | |  |  \| || |  \/| |__  | |_/ / "
ECHO " |  __/   | |  | . ` || | __ |  __| |    /  "
ECHO " | |     _| |_ | |\  || |_\ \| |___ | |\ \  "
ECHO " \_|     \___/ \_| \_/ \____/\____/ \_| \_| "
ECHO "============================================"
ECHO[
EXIT /B 0