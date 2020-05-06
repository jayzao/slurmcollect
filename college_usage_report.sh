#!/bin/bash

set -euo pipefail	# http://redsymbol.net/articles/unofficial-bash-strict-mode/

source /packages/sysadmin/scripts/header.source

source globals.source

# Only run this script on our slurm servers
#if [ "$SHORTHOST" != "ldap1" -a "$SHORTHOST" != "bigslurm" -a "$SHORTHOST" != "slurm" ] ; then

#	echo-red "\nThis script should be run on a slurm server\n"
#	exit

#fi

if [ $# -ne 3 ] ; then

	echo -e "Gotta give me a start date, an end date, and an email address\n"
	echo -e "usage: ./college_usage_report.sh 2015-07-01 2016-07-01 myemail@asu.edu\n"
	exit

fi

START=$1
END=$2
EMAIL=$3

FILENAME=college_usage

MUTTCONFIG=/packages/sysadmin/saguaro_slurm/database/new_report_scripts/muttconfig

/bin/rm -f /tmp/output.csv
/bin/rm -f /tmp/${FILENAME}_${A2C2_CLUSTERNAME}.*

echo -e "${A2C2_CLUSTERNAME} college usage" > /tmp/template
echo -e "from $START to $END\n" >> /tmp/template
echo -e "COLLEGE_NAME,COLLEGE_DESCRIPTION,COLLEGE_REPORTNAME,CPU_HOURS" >> /tmp/template

QUERY=\
"select
	colleges.name,
	colleges.description,
	colleges.ReportName,
	round(sum(cpu_hours)) as cpu_hours
from
	show_completed_jobs
inner join
	colleges
on
	show_completed_jobs.college = colleges.name
where
	start >= '$START'
and
	end <= '$END'
group by
	college
order by
	college"

mysql -h $MYSQL_SERVER -u $MYSQL_USER -p${MYSQL_PASSWORD} -N $MYSQL_DATABASE -e "$QUERY" 2> /dev/null | tr '\t' ',' > /tmp/output.csv

cat /tmp/template /tmp/output.csv | sed -e 's/a2c2/ARC/gI' > /tmp/${FILENAME}_${A2C2_CLUSTERNAME}.csv

soffice --headless --convert-to xls /tmp/${FILENAME}_${A2C2_CLUSTERNAME}.csv --outdir /tmp > /dev/null
#soffice --headless --convert-to xlsx:"Calc MS Excel 2007 XML" /tmp/${FILENAME}_${A2C2_CLUSTERNAME}.csv --outdir /tmp  > /dev/null
#soffice --headless --convert-to xlsx /tmp/${FILENAME}_${A2C2_CLUSTERNAME}.csv --outdir /tmp > /dev/null
#soffice --headless --convert-to html /tmp/${FILENAME}_${A2C2_CLUSTERNAME}.csv --outdir /tmp > /dev/null
#soffice --headless --convert-to ods /tmp/${FILENAME}_${A2C2_CLUSTERNAME}.csv --outdir /tmp > /dev/null

echo -e "${A2C2_CLUSTERNAME} college usage report between $START and $END\n\nGenerated at $(date +'%F @ %T') for $EMAIL" | \
    mutt -F $MUTTCONFIG \
	-a /tmp/${FILENAME}_${A2C2_CLUSTERNAME}.csv \
	-a /tmp/${FILENAME}_${A2C2_CLUSTERNAME}.xls \
	-b Lee.Reynolds@asu.edu \
	-s "${A2C2_CLUSTERNAME} college usage report $START : $END" \
	-- $EMAIL

#	-a /tmp/${FILENAME}_${A2C2_CLUSTERNAME}.html \
#	-a /tmp/${FILENAME}_${A2C2_CLUSTERNAME}.ods \

