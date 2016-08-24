#!/bin/bash
# mysql 데이터베이스 덤프 백업
# by @rokwha
# rev. 1 - 2016-08-24
#	  mysql_full_dump.cmd fork

# 날자설정 f_date만 쓰지만.. 기냥..
f_date_year=`date "+%Y"`
f_date_mon=`date "+%m"`
f_date_day=`date "+%d"`
f_date=`date "+%Y%m%d"`

# mysql 계정정보 - 적절히 알아서 잘~
host="localhost"
user="user"
pass="pass"

# 유틸리티
mysql_exe="mysql"
mysql_exe_dump="mysqldump"

# 각종명령
mysql_info_account="-h $host -u $user -p$pass"
mysql_info_databases="$mysql_exe $mysql_info_account -e 'show databases' -s -N"
mysql_info_tables="$mysql_exe $mysql_info_account -e \"show tables from "
mysql_cmd_="$mysql_exe $mysql_info_account"
mysql_cmd_dump_table="$mysql_exe_dump $mysql_info_account -c -C --skip-opt "

# 압축명령 - 입맛대로 선택하고 옵션조절하고 알아서 쓰셈 
archive_cmd="tar cfzP "
#archive_cmd="zip -9 "
#archive_cmd="7zr a "
archive_use_perfile=1
archive_filename=$f_date.tar.gz

# 디렉토리 - 필요할 경우 소유권/권한 확인및 조취
dir_backup_main="/home/rokwha/backup/$host"
dir_backup_temp="/home/rokwha/backup/temp/$host"

# 디렉토리 없으면 생성
if [ ! -d $dir_backup_main ]; then 
	mkdir -p $dir_backup_main
fi

if [ ! -d $dir_backup_temp ]; then
	mkdir -p $dir_backup_temp
fi

#IFS='\n'
# 아쒸 왜안되지?
# ADATABASES=(`$mysql_info_databases`)
# ADATABASES=(`"$mysql_info_databases"`)
ADATABASES=(`$mysql_cmd_ -e "show databases" -s -N | tail -n+2`)
#데이터베이스 루프
for database in "${ADATABASES[@]}"; do
	if [ ! -d "$dir_backup_temp/$database" ]; then 
		mkdir -p "$dir_backup_temp/$database"
	fi
	ATABLES=(`$mysql_cmd_ -e "show tables from $database" -s -N`)
	#테이블 루프
	for table in "${ATABLES[@]}"; do
		$mysql_cmd_dump_table $database $table --result-file=$dir_backup_temp/$database/$table.sql
		# todo 덤프받다 오류나는거 로그남기기 덤프뜰때 메세지를 손쉽게 처리하면 되는데..아 귀찮다
		if [[ `echo $?` -ne 0 ]]; then
			#일단 데이블명 이라도 로그남길려면..여기서
			echo $database.$table 
		fi
	done
	#데이터베이스별 파일압축 
	#여긴 압축률 최저로 하면 좋을듯 걍 tar 로 묶던지
	if [ $archive_use_perfile -eq 1 ]; then
		#tar로 압축할경우 절대경로 와 상대경로 의 차이점 때문에...
		#$archive_cmd $dir_backup_temp/$database.tar.gz $dir_backup_temp/$database/ > /dev/null 
		cd $dir_backup_temp/$database/
		$archive_cmd $dir_backup_temp/$database.tar.gz ./
	fi
done

#데이터베이스별로 압축된것 하나로 묶기 또는 통압축하기
cd $dir_backup_temp/
if [ $archive_use_perfile -eq 1 ]; then
	#$archive_cmd $dir_backup_temp/$archive_filename $dir_backup_temp/*.tar.gz > /dev/null
	$archive_cmd $dir_backup_temp/$archive_filename ./*.tar.gz
else
	#$archive_cmd $dir_backup_temp/$archive_filename $dir_backup_temp/ > /dev/null
	$archive_cmd $dir_backup_temp/$archive_filename ./
fi

#최종백업파일 옮기기
cp $dir_backup_temp/$archive_filename $dir_backup_main/

#최종 백업파일 에서 최근 n일치 남기고 나머지 삭제 
#tail 옵션에서 숫자변경 또는 ls 와 sort 옵션을 잘 적절히 ...
AFILES=(`ls /$dir_backup_main/ | sort -r -k 1 | tail -n+7`)
for filename in "${AFILES[@]}"; do
	rm -f $filename
done

#임시디렉토리 정리
rm -rf $dir_backup_temp
