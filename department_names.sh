#!/bin/bash

set -euo pipefail	# http://redsymbol.net/articles/unofficial-bash-strict-mode/

source /packages/sysadmin/scripts/header.source

source globals.source

# Only run this script on our slurm servers
#if [ "$SHORTHOST" != "ldap1" -a "$SHORTHOST" != "bigslurm" -a "$SHORTHOST" != "slurm" ] ; then

#	echo-red "\nThis script should be run on a slurm server\n"
#	exit

#fi

if [ $# -ne 1 ] ; then

	echo -e "\nGotta give me an email address\n"
	echo -e "usage: ./department_names.sh myemail@asu.edu\n"
	exit

fi

EMAIL=$1

FILENAME=department_names

/bin/rm -f /tmp/output.csv
/bin/rm -f /tmp/${FILENAME}_${A2C2_CLUSTERNAME}.*

echo -e "${A2C2_CLUSTERNAME} department names" > /tmp/template
echo -e "NAME,URL,DESCRIPTION,REPORTNAME,COLLEGE,INSTITUTION" >> /tmp/template

QUERY=\
"select
	*
from
	departments
order by
	college"

mysql -h $MYSQL_SERVER -u $MYSQL_USER -p${MYSQL_PASSWORD} -N $MYSQL_DATABASE -e "$QUERY" 2> /dev/null | tr '\t' ',' > /tmp/output.csv

cat /tmp/template /tmp/output.csv | sed -e 's/a2c2/ARC/gI' > /tmp/${FILENAME}_${A2C2_CLUSTERNAME}.csv

soffice --headless --convert-to xls /tmp/${FILENAME}_${A2C2_CLUSTERNAME}.csv --outdir /tmp > /dev/null
#soffice --headless --convert-to xlsx:"Calc MS Excel 2007 XML" /tmp/${FILENAME}_${A2C2_CLUSTERNAME}.csv --outdir /tmp  > /dev/null
#soffice --headless --convert-to xlsx /tmp/${FILENAME}_${A2C2_CLUSTERNAME}.csv --outdir /tmp > /dev/null
#soffice --headless --convert-to html /tmp/${FILENAME}_${A2C2_CLUSTERNAME}.csv --outdir /tmp > /dev/null
#soffice --headless --convert-to ods /tmp/${FILENAME}_${A2C2_CLUSTERNAME}.csv --outdir /tmp > /dev/null

echo -e "${A2C2_CLUSTERNAME} department names generated at $(date +'%F @ %T') for $EMAIL" | \
    mutt -F $MUTTCONFIG \
	-a /tmp/${FILENAME}_${A2C2_CLUSTERNAME}.csv \
	-a /tmp/${FILENAME}_${A2C2_CLUSTERNAME}.xls \
	-s "${A2C2_CLUSTERNAME} department names" \
	-- $EMAIL

#	-a /tmp/${FILENAME}_${A2C2_CLUSTERNAME}.html \
#	-a /tmp/${FILENAME}_${A2C2_CLUSTERNAME}.ods \

