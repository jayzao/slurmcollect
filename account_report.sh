#!/bin/bash
# JAE Arizona State University 2016 
# clustername A2C2_Clustername, email, Slurm server

set -euo pipefail	# http://redsymbol.net/articles/unofficial-bash-strict-mode/

source /packages/sysadmin/scripts/header.source

source globals.source

# Only run this script on our slurm servers
#if [ "$SHORTHOST" != "ldap1" -a "$SHORTHOST" != "bigslurm" -a "$SHORTHOST" != "slurm" ] ; then

#	echo-red "\nThis script should be run on a slurm server\n"
#	exit

#fi


if [ $# -ne 1 ] ; then

	echo-yellow "\nGotta give me an email address\n"
	echo-yellow "usage: ./accounts_report.sh myemail@asu.edu\n"
	exit

fi

EMAIL=$1

FILENAME=accounts

#echo -e "\nAccount Report\n"

/bin/rm -f /tmp/output.csv
/bin/rm -f /tmp/${FILENAME}_${A2C2_CLUSTERNAME}.*

echo -e "${A2C2_CLUSTERNAME} active accounts\n" > /tmp/template
echo -e "NAME,TYPE,DESCRIPTION,ACTIVE,DELETED,ASURITE,OWNER,EMAIL,DEPARTMENT,COLLEGE,INSTITUTION" >> /tmp/template

QUERY=\
"select 
	accounts.Name,
	accounts.Type,
	accounts.Description,
	accounts.Active,
	accounts.Deleted,
	accounts.asurite,
	accounts.owner,
	a2c2_people.email,
	accounts.department,
	accounts.college,
	accounts.institution
from 
	accounts
inner join
	a2c2_people
on
	accounts.asurite = a2c2_people.name
order by
	name"

mysql -h $MYSQL_SERVER -u $MYSQL_USER -p${MYSQL_PASSWORD} -N $MYSQL_DATABASE -e "$QUERY" 2> /dev/null | tr '\t' ',' > /tmp/output.csv

cat /tmp/template /tmp/output.csv | sed -e 's/a2c2/ARC/gI' > /tmp/${FILENAME}_${A2C2_CLUSTERNAME}.csv

soffice --headless --convert-to xls /tmp/${FILENAME}_${A2C2_CLUSTERNAME}.csv --outdir /tmp > /dev/null
#soffice --headless --convert-to xlsx:"Calc MS Excel 2007 XML" /tmp/${FILENAME}_${A2C2_CLUSTERNAME}.csv --outdir /tmp 
#soffice --headless --convert-to xlsx /tmp/${FILENAME}_${A2C2_CLUSTERNAME}.csv --outdir /tmp > /dev/null
#soffice --headless --convert-to html /tmp/${FILENAME}_${A2C2_CLUSTERNAME}.csv --outdir /tmp > /dev/null
#soffice --headless --convert-to ods /tmp/${FILENAME}_${A2C2_CLUSTERNAME}.csv --outdir /tmp > /dev/null

echo -e "Account information for ${A2C2_CLUSTERNAME} cluster\n\nGenerated at $(date +'%F @ %T') for $EMAIL" | \
    mutt -F $MUTTCONFIG \
	-a /tmp/${FILENAME}_${A2C2_CLUSTERNAME}.xls \
	-a /tmp/${FILENAME}_${A2C2_CLUSTERNAME}.csv \
	-s "${A2C2_CLUSTERNAME} account information" -- $EMAIL

#	-a /tmp/${FILENAME}_${A2C2_CLUSTERNAME}.html \
#	-a /tmp/${FILENAME}_${A2C2_CLUSTERNAME}.ods \
