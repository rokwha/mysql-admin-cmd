@echo off
rem mysql 데이터베이스 덤프 백업
rem by @rokwha
rem rev. 2 - 2017-03-17
rem   mysql_full_dump.cmd 에서 조금 변형
rem   덤프할 데이터베이스 와 테이블 목록을 미리 만들어서 해당 데이터베이스 와 테이블만 덤프한다.
rem   use_opt_database_file, use_opt_table_file 의 값이 0 이면 서버에 있는거 몽땅, 1 이면 지정된 파일내용으로..
rem   파일이 없을경우 서버에 있는거 몽땅~
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
set user=user
set pass=pass

rem 유틸리티 
set mysql_exe=mysql.exe 
set mysql_exe_dump=mysqldump.exe
set archive_exe=7z.exe

rem 각종 명령
set mysql_info_account=-h %host% -u %user% -p%pass%
set mysql_info_databases=%mysql_exe% %mysql_info_account% -e "show databases" -s -N
set mysql_info_tables=%mysql_exe% %mysql_info_account% -e "show tables from
set mysql_cmd_dump_table=%mysql_exe_dump% %mysql_info_account% -c -C --skip-opt 
set mysql_dump_per_file=1
set mysql_dump_one_file=1

rem 압축명령 - 패스워드 필요없을경우 -p 옵션 제거 
set archive_pass=%pass%
set archive_cmd=%archive_exe% a -bd -p%archive_pass%
set archive_use_per_database=0

rem 디렉토리
set dir_backup_main=r:\work\backup\%host%
set dir_backup_temp=r:\work\backup\temp
set dir_backup_option=r:\work\backup

rem 디렉토리 없으면 생성
if not exist %dir_backup_main%\ (
	md %dir_backup_main%
	echo %dir_backup_main% create
)

if not exist %dir_backup_temp%\ (
	md %dir_backup_temp%
	echo %dir_backup_temp% create
)

rem 덤프할 데이터베이스 목록파일
set use_opt_database_file=1
set opt_database_file=%dir_backup_option%\opt_database.list 
rem use_opt_database_file 이 0 이면 mysql_info_databases 로 파일을 만든다.
if %use_opt_database_file% EQU 0 (
  %mysql_info_databases% > %opt_database_file%
)
if not exist %opt_database_file% (
  echo 파일엄?~ 만드시오~ 예외처리 알아서 하시오~
  %mysql_info_databases% > %opt_database_file%  
)
rem 덤프할 테이블 목록
rem 테이블 목록 파일을 사용할 경우 데이터베이스.table.list 이름으로 dir_backup_option 디렉토리에 미리 만들어넣어둔다.
rem 파일이 없을경우 show tables 명령을 사용해 모두 처리한다.
set use_opt_table_file=1


rem 데이터베이스 루프
for /f %%d in (%opt_database_file%) do (
	set database=%%d
	rem use_opt_database_file=1 일경우 데이터베이스 목록을 미리 편집해놨으므로 목록 전부를 덤프한다.
  if not exist %dir_backup_temp%\!database!\ (
		md %dir_backup_temp%\!database!
	)
	rem cd %dir_backup_temp%\!database!
	rem 테이블 루프
  rem use_opt_table_file=0 이면 mysql_info_tables 로 테이블 목록을 추출한다.
  set opt_table_file=%dir_backup_option%\!database!.table.list
  if %use_opt_table_file% EQU 0 (
    %mysql_info_tables% !database!" -s -N > !opt_table_file!
  )
  if not exist !opt_table_file! (
    echo 파일엄?~ 만드시오~ 예외처리 알아서 하시오~
    %mysql_info_tables% !database!" -s -N > !opt_table_file!
  )
  rem 데이터베이스 통 덤프받을것인가?
  if %mysql_dump_one_file% equ 1 (
    %mysql_cmd_dump_table% !database! --result_file=%dir_backup_temp%\!database!\0.all-tables.sql      
  )
  if %mysql_dump_per_file% equ 1 (
    for /f %%t in (!opt_table_file!) do (
      set table=%%t
      echo !database!.!table!
      rem 테이블 당 하나의 파일로 덤프
      rem todo 덤프 에러났을경우 로그남기기      
      %mysql_cmd_dump_table% !database! !table! --result_file=%dir_backup_temp%\!database!\!table!.sql      
    )
  )
	if %archive_use_per_database% equ 1 (
		rem 데이터베이스 별로 압축하기 통파일로 할경우 주석 처리
		%archive_cmd% -mx=9 %dir_backup_temp%\!database!.7z %dir_backup_temp%\!database!\*.sql
	)
)
rem 압축
rem 디렉토리별로 덤프받은 파일을 통으로 압축할 경우 주석해제
if %archive_use_per_database% neq 1 (
  %archive_cmd% -mx=9 -r0 %dir_backup_temp%\%f_date%.7z %dir_backup_temp%\*.sql
) else (
  rem 개별압축 한것을 사용할경우 주석해제 - 개별압축된것 하나의 파일로 묶음
  %archive_cmd% -mx=0 %dir_backup_temp%\%f_date%.7z %dir_backup_temp%\*.7z
)
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

