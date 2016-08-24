@echo off
rem mysql 데이터베이스 덤프 백업
rem by @rokwha
rem rev. 1 - 2016-08-24
rem 	그냥 몽땅 백업만 하기.
		
setlocal enabledelayedexpansion

rem 날자설정 시스템에 따라 다르게 나올수 있으므로 환경에 따라 적절하게변경
set fdate=%date%
set f_date_year=%fdate:~0,4%
set f_date_mon=%fdate:~5,2%
set f_date_day=%fdate:~8,2%
set f_date=%f_date_year%%f_date_mon%%f_date_day%

rem mysql 계정정보-적절히 알아서~ 잘~
set host=localhost
set user=username
set pass=userpass

rem 유틸리티 
set mysql_exe=mysql.exe 
set mysql_exe_dump=mysqldump.exe
set archive_exe=7z.exe

rem 각종 명령
set mysql_info_account=-h %host% -u %user% -p%pass%
set mysql_info_databases=%mysql_exe% %mysql_info_account% -e "show databases" -s -N
set mysql_info_tables=%mysql_exe% %mysql_info_account% -e "show tables from
set mysql_cmd_dump_table=%mysql_exe_dump% %mysql_info_account% -c -C --skip-opt 

rem 압축명령 - 패스워드 필요없을경우 -p 옵션 제거 
set archive_cmd=%archive_exe% a -bd -p%pass%

rem 디렉토리
set dir_backup_main=r:\work\backup\%host%
set dir_backup_temp=r:\work\backup\temp

rem 디렉토리 없으면 생성
if not exist %dir_backup_main%\ (
	md %dir_backup_main%
)

if not exist %dir_backup_temp%\ (
	md %dir_backup_temp%
)

rem 데이터베이스 루프
for /f %%d in ('%mysql_info_databases%') do (
	set database=%%d
	rem information_schema 하고 mysql 데이터베이스는 제외 - 필요할경우 주석처리 
	if not !database! == information_schema ( 
		rem if not !database! == mysql (
			if not exist %dir_backup_temp%\!database!\ (
				md %dir_backup_temp%\!database!
			)
			rem cd %dir_backup_temp%\!database!
			rem 테이블 루프
			for /f %%t in ('%mysql_info_tables% !database!" -s -N') do (
				set table=%%t
				rem echo !database!.!table!
				rem 테이블 당 하나의 파일로 덤프
				rem %mysql_cmd_dump_table% !database! !table! > %dir_backup_temp%\!database!\!table!.sql
				%mysql_cmd_dump_table% !database! !table! --result_file=%dir_backup_temp%\!database!\!table!.sql
				rem todo 덤프 에러났을경우 로그남기기
			)
			rem 데이터베이스 별로 압축하기 통파일로 할경우 주석 처리
			rem %archive_cmd% -mx=9 %dir_backup_temp%\!database!.7z -p%pass% %dir_backup_temp%\!database!\*.sql
			rem del %dir_backup_temp%\!database!\*.sql 
		rem )
	)
)

rem 압축
rem 디렉토리별로 덤프받은 파일을 통으로 압축할 경우 주석해제
%archive_cmd% -mx=9 -r0 %dir_backup_temp%\%f_date%.7z -p%pass% %dir_backup_temp%\*.*

rem 개별압축 한것을 사용할경우 주석해제 - 개별압축된것 하나의 파일로 묶음
rem %archive_cmd% -mx=0 %dir_backup_temp%\%f_date%.7z %dir_backup_temp%\*.7z

copy %dir_backup_temp%\%f_date%.7z %dir_backup_main%\

rem 임시디렉토리/파일 삭제
del %dir_backup_temp%\ /s /q > nul
rd %dir_backup_temp%\ /s /q > nul

rem 백업파일을 n일 지난것들은 삭제하자 ( 일별 로 날짜로 파일명이 생성되니 이름으로 역순정렬하여 최근 n개만 남겨두고 나머진 삭제)
rem 파일명이 날자가 아니고 일별로 하나씩 생성된다면 날자/시간으로 소트하면 될듯 
rem skip=7 <- 숫자조절 하면 됨

set dir_cmd=dir %dir_backup_main%\%f_year%*.7z /b /o-n 
for /f "skip=7" %%f in ('%dir_cmd%') do (
	del %%f /q > nul
)

endlocal

