ECHO OFF
REM application to perform XSLT transformation
set AltovaXML="C:\Program Files (x86)\Altova\AltovaXML2012\AltovaXML.exe"
set XSLT="AAT-mappings-to-JSON.xslt"
set format=nt
REM set format=json

REM get timestamp (for naming output files)
set yyyy=%date:~6,4%
set mm=%date:~3,2%
set dd=%date:~0,2%
set hh=%time:~0,2%
if %hh% lss 10 (set hh=0%time:~1,1%)
set nn=%time:~3,2%
set ss=%time:~6,2%
set datestamp=%yyyy%%mm%%dd%
set timestamp=%yyyy%%mm%%dd%%hh%%nn%%ss%
ECHO ON

REM convert each .\clean-TXT\*.txt file to JSON using XSLT template
for /f %%f in ('dir /B /L .\clean-TXT\*.txt') do %AltovaXML% -xslt2 %XSLT% -in dummy.xml -out ./%format%/%%~nf-%datestamp%.%format% -param inputFilePath='./clean-TXT/%%f' -param format='%format%' -param source='%%~nf'

