@echo off
rem mysql �����ͺ��̽� ���� ���
rem by @rokwha
rem rev. 2 - 2017-03-17
rem   mysql_full_dump.cmd ���� ���� ����
rem   ������ �����ͺ��̽� �� ���̺� ����� �̸� ���� �ش� �����ͺ��̽� �� ���̺� �����Ѵ�.
rem   use_opt_database_file, use_opt_table_file �� ���� 0 �̸� ������ �ִ°� ����, 1 �̸� ������ ���ϳ�������..
rem   ������ ������� ������ �ִ°� ����~
rem rev. 1 - 2016-08-24
rem 	�׳� ���� ����� �ϱ�.
		
setlocal enabledelayedexpansion

rem ���ڼ��� �ý��ۿ� ���� �ٸ��� ���ü� �����Ƿ� ȯ�濡 ���� �����ϰԺ���
set fdate=%date%
set f_date_year=%fdate:~0,4%
set f_date_mon=%fdate:~5,2%
set f_date_day=%fdate:~8,2%
set f_date=%f_date_year%%f_date_mon%%f_date_day%

rem mysql ��������-������ �˾Ƽ�~ ��~
set host=localhost
set user=user
set pass=pass

rem ��ƿ��Ƽ 
set mysql_exe=mysql.exe 
set mysql_exe_dump=mysqldump.exe
set archive_exe=7z.exe

rem ���� ���
set mysql_info_account=-h %host% -u %user% -p%pass%
set mysql_info_databases=%mysql_exe% %mysql_info_account% -e "show databases" -s -N
set mysql_info_tables=%mysql_exe% %mysql_info_account% -e "show tables from
set mysql_cmd_dump_table=%mysql_exe_dump% %mysql_info_account% -c -C --skip-opt 
set mysql_dump_per_file=1
set mysql_dump_one_file=1

rem ������ - �н����� �ʿ������� -p �ɼ� ���� 
set archive_pass=%pass%
set archive_cmd=%archive_exe% a -bd -p%archive_pass%
set archive_use_per_database=0

rem ���丮
set dir_backup_main=r:\work\backup\%host%
set dir_backup_temp=r:\work\backup\temp
set dir_backup_option=r:\work\backup

rem ���丮 ������ ����
if not exist %dir_backup_main%\ (
	md %dir_backup_main%
	echo %dir_backup_main% create
)

if not exist %dir_backup_temp%\ (
	md %dir_backup_temp%
	echo %dir_backup_temp% create
)

rem ������ �����ͺ��̽� �������
set use_opt_database_file=1
set opt_database_file=%dir_backup_option%\opt_database.list 
rem use_opt_database_file �� 0 �̸� mysql_info_databases �� ������ �����.
if %use_opt_database_file% EQU 0 (
  %mysql_info_databases% > %opt_database_file%
)
if not exist %opt_database_file% (
  echo ���Ͼ�?~ ����ÿ�~ ����ó�� �˾Ƽ� �Ͻÿ�~
  %mysql_info_databases% > %opt_database_file%  
)
rem ������ ���̺� ���
rem ���̺� ��� ������ ����� ��� �����ͺ��̽�.table.list �̸����� dir_backup_option ���丮�� �̸� �����־�д�.
rem ������ ������� show tables ����� ����� ��� ó���Ѵ�.
set use_opt_table_file=1


rem �����ͺ��̽� ����
for /f %%d in (%opt_database_file%) do (
	set database=%%d
	rem use_opt_database_file=1 �ϰ�� �����ͺ��̽� ����� �̸� �����س����Ƿ� ��� ���θ� �����Ѵ�.
  if not exist %dir_backup_temp%\!database!\ (
		md %dir_backup_temp%\!database!
	)
	rem cd %dir_backup_temp%\!database!
	rem ���̺� ����
  rem use_opt_table_file=0 �̸� mysql_info_tables �� ���̺� ����� �����Ѵ�.
  set opt_table_file=%dir_backup_option%\!database!.table.list
  if %use_opt_table_file% EQU 0 (
    %mysql_info_tables% !database!" -s -N > !opt_table_file!
  )
  if not exist !opt_table_file! (
    echo ���Ͼ�?~ ����ÿ�~ ����ó�� �˾Ƽ� �Ͻÿ�~
    %mysql_info_tables% !database!" -s -N > !opt_table_file!
  )
  rem �����ͺ��̽� �� �����������ΰ�?
  if %mysql_dump_one_file% equ 1 (
    %mysql_cmd_dump_table% !database! --result_file=%dir_backup_temp%\!database!\0.all-tables.sql      
  )
  if %mysql_dump_per_file% equ 1 (
    for /f %%t in (!opt_table_file!) do (
      set table=%%t
      echo !database!.!table!
      rem ���̺� �� �ϳ��� ���Ϸ� ����
      rem todo ���� ����������� �α׳����      
      %mysql_cmd_dump_table% !database! !table! --result_file=%dir_backup_temp%\!database!\!table!.sql      
    )
  )
	if %archive_use_per_database% equ 1 (
		rem �����ͺ��̽� ���� �����ϱ� �����Ϸ� �Ұ�� �ּ� ó��
		%archive_cmd% -mx=9 %dir_backup_temp%\!database!.7z %dir_backup_temp%\!database!\*.sql
	)
)
rem ����
rem ���丮���� �������� ������ ������ ������ ��� �ּ�����
if %archive_use_per_database% neq 1 (
  %archive_cmd% -mx=9 -r0 %dir_backup_temp%\%f_date%.7z %dir_backup_temp%\*.sql
) else (
  rem �������� �Ѱ��� ����Ұ�� �ּ����� - ��������Ȱ� �ϳ��� ���Ϸ� ����
  %archive_cmd% -mx=0 %dir_backup_temp%\%f_date%.7z %dir_backup_temp%\*.7z
)
copy %dir_backup_temp%\%f_date%.7z %dir_backup_main%\

rem �ӽõ��丮/���� ����
del %dir_backup_temp%\ /s /q > nul
rd %dir_backup_temp%\ /s /q > nul

rem ��������� n�� �����͵��� �������� ( �Ϻ� �� ��¥�� ���ϸ��� �����Ǵ� �̸����� ���������Ͽ� �ֱ� n���� ���ܵΰ� ������ ����)
rem ���ϸ��� ���ڰ� �ƴϰ� �Ϻ��� �ϳ��� �����ȴٸ� ����/�ð����� ��Ʈ�ϸ� �ɵ� 
rem skip=7 <- �������� �ϸ� ��

set dir_cmd=dir %dir_backup_main%\%f_year%*.7z /b /o-n 
for /f "skip=7" %%f in ('%dir_cmd%') do (
	del %%f /q > nul
)

endlocal

