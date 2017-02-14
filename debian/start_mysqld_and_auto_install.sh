#!/bin/sh
#
# start_mysqld_and_auto_install.sh - starts an instance of mysqld before
# auto_installing and running do_mysql's test suite. It is inspired by
# debian/test_mysql.sh from libdbi-drivers source package.



set -e

MYTEMP_DIR=`mktemp -d`
ME=`whoami`

export MYSQL_UNIX_PORT=${MYTEMP_DIR}/mysql.sock
DO_MYSQL_USER=root
DO_MYSQL_PASS=
DO_MYSQL_DBNAME=do_test
DO_MYSQL_DATABASE=/${DO_MYSQL_DBNAME}

/usr/sbin/mysqld --no-defaults --initialize-insecure --datadir=${MYTEMP_DIR} --user=${ME}
/usr/sbin/mysqld --no-defaults --user=${DO_MYSQL_USER} --socket=${MYSQL_UNIX_PORT} --datadir=${MYTEMP_DIR} --skip-networking &
echo -n pinging mysqld.
attempts=0
while ! /usr/bin/mysqladmin -uroot --socket=${MYSQL_UNIX_PORT} ping ; do
	sleep 3
	attempts=$((attempts+1))
	if [ ${attempts} -gt 10 ] ; then
		echo "skipping test, mysql server could not be contacted after 30 seconds"
		exit 0
	fi
done
mysql -uroot --socket=${MYSQL_UNIX_PORT} --execute "CREATE DATABASE ${DO_MYSQL_DBNAME};"
mysql -uroot --socket=${MYSQL_UNIX_PORT} --execute "GRANT ALL PRIVILEGES ON ${DO_MYSQL_DBNAME}.* TO '${DO_MYSQL_USER}'@'localhost' IDENTIFIED BY '${DO_MYSQL_PASS}';"

# Keep running so we can terminate mysqld.
set +e

dh_auto_install
RC=$?

/usr/bin/mysqladmin -uroot --socket=${MYSQL_UNIX_PORT} shutdown
rm -rf ${MYTEMP_DIR}

exit $RC
