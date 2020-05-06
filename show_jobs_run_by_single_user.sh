#!/bin/bash

set -euo pipefail	# http://redsymbol.net/articles/unofficial-bash-strict-mode/

source /packages/sysadmin/scripts/header.source

source globals.source

# Only run this script on our slurm servers
if [ "$SHORTHOST" != "ldap1" -a "$SHORTHOST" != "bigslurm" -a "$SHORTHOST" != "slurm" ] ; then

	echo-red "\nThis script should be run on a slurm server\n"
	exit

fi

if [ $# -ne 4 ] ; then

	echo -e "\nGotta give me a start date, an end date, a username, and an email address\n"
	echo -e "usage: ./show_jobs_run_by_single_user.sh 2015-07-01 2016-07-01 joebob myemail@asu.edu\n"
	exit

fi

START=$1
END=$2
USERNAME=$3
EMAIL=$4

FILENAME=jobs_run_by_single_user_$USERNAME

/bin/rm -f /tmp/output.csv
/bin/rm -f /tmp/${FILENAME}_${A2C2_CLUSTERNAME}.*

echo -e "${A2C2_CLUSTERNAME} jobs run by user $USERNAME" > /tmp/template
echo -e "from $START to $END\n" >> /tmp/template
#echo -e "ASURITE,NAME,EMAIL,ACCOUNT,ACCOUNT_OWNER,DEPARTMENT,COLLEGE,HOURS" >> /tmp/template
echo -e "ASURITE,FULLNAME,JOBID,ACCOUNT,JOBNAME,PARTITION,CPUS_REQ,MEMORY,NODELIST,NODES_ALLOC,NODE_INX,EXIT_CODE,STATE,SUBMIT,ELIGIBLE,START,END,TIMELIMIT,WAIT,RUNTIME,CPU_HOURS" >> /tmp/template
#echo -e "ASURITE\tFULLNAME\tJOBID\tQOS\tACCOUNT\tJOBNAME\tCPUS_REQ\tMEMORY\tNODELIST\tNODES_ALLOC\tNODE_INX\tEXIT_CODE\tSTATE\tSUBMIT\tELIGIBLE\tSTART\tEND\tTIMELIMIT\tWAIT\tRUNTIME\tCPU_HOURS" >> /tmp/template

mysql slurm_acct_db -e "

use slurm_acct_db

select
	asurite,
	fullname,
	jobid,
	account,
	jobname,
	show_completed_jobs.partition,
	cpus_req,
	memory,
	nodelist,
	nodes_alloc,
	node_inx,
	exit_code,
	state,
	submit,
	eligible,
	start,
	end,
	timelimit,
	wait,
	runtime,
	cpu_hours
from
	show_completed_jobs
where
	asurite = '$USERNAME'
and
	start >= '$START'
and
	end <= '$END'
order by
	jobid
into outfile '/tmp/output.csv'
FIELDS TERMINATED BY ','
ENCLOSED BY '\"'
LINES TERMINATED BY '\n';
"

cat /tmp/template /tmp/output.csv | sed -e 's/a2c2/ARC/gI' > /tmp/${FILENAME}_${A2C2_CLUSTERNAME}.csv

soffice --headless --convert-to xls /tmp/${FILENAME}_${A2C2_CLUSTERNAME}.csv --outdir /tmp > /dev/null
#soffice --headless --convert-to xlsx:"Calc MS Excel 2007 XML" /tmp/${FILENAME}_${A2C2_CLUSTERNAME}.csv --outdir /tmp  > /dev/null
#soffice --headless --convert-to xlsx /tmp/${FILENAME}_${A2C2_CLUSTERNAME}.csv --outdir /tmp > /dev/null
#soffice --headless --convert-to html /tmp/${FILENAME}_${A2C2_CLUSTERNAME}.csv --outdir /tmp > /dev/null
soffice --headless --convert-to ods /tmp/${FILENAME}_${A2C2_CLUSTERNAME}.csv --outdir /tmp > /dev/null

echo "${A2C2_CLUSTERNAME} jobs run by user $USERNAME between $START and $END" | mutt \
	-a /tmp/${FILENAME}_${A2C2_CLUSTERNAME}.xls \
	-a /tmp/${FILENAME}_${A2C2_CLUSTERNAME}.csv \
	-a /tmp/${FILENAME}_${A2C2_CLUSTERNAME}.ods \
	-s "${A2C2_CLUSTERNAME} jobs run by user $USERNAME between $START : $END" \
	-- $EMAIL

#	-a /tmp/${FILENAME}_${A2C2_CLUSTERNAME}.html \
