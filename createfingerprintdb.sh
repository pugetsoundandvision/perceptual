#!/bin/bash

SCRIPTDIR=$(dirname "${0}")
DBCONFIG="${SCRIPTDIR}"/FINGERPRINTDB_CONFIG.txt

usage(){
    echo "This script will configure a database, users and login profiles"
    echo "Usage: -c (create database) -u (create user) -h (help)"
}

_error_check(){
#verify success of operation
if [ "$?" != "0" ]; then
echo -e "\033[1;103;95mERROR:Please confirm inputs and try again.\033[0m"
mysql_config_editor remove --login-path=tempsetting
exit 1
fi
}

if [ -f "${DBCONFIG}" ] ; then
    echo "DB CONFIG ALREADY EXISTS. PLEASE DELETE OR MOVE TO CONFIGURE NEW DATABASE. EXITING." && exit
fi

#get input for database creation
echo "This script will create the database used by mm on your localhost."
echo "Please enter root password for mysql:"
mysql_config_editor set --login-path=tempsetting --host=localhost --user=root --password
echo "Please enter name of DB to be created"
read -r DB_NAME

#create database
echo "CREATE DATABASE "$DB_NAME"" | mysql --login-path=tempsetting
_error_check
echo "CREATE TABLE object (objectIdentifierValueID bigint NOT NULL AUTO_INCREMENT,objectIdentifierValue varchar(1000) NOT NULL UNIQUE,objectDB_Insertion datetime NOT NULL DEFAULT NOW(),object_LastTouched datetime NOT NULL,PRIMARY KEY (objectIdentifierValueID))" | mysql --login-path=tempsetting "$DB_NAME"
echo "CREATE TABLE fingerprints (hashNumber bigint NOT NULL AUTO_INCREMENT, objectIdentifierValue varchar(1000) NOT NULL,startframe varchar(100),endframe varchar(100),hash1 varchar(27),hash2 varchar(27),hash3 varchar(27),hash4 varchar(27),hash5 varchar(27),hash6 varchar(27),hash7 varchar(27),hash8 varchar(27),hash9 varchar(27), PRIMARY KEY (hashNumber))" | mysql --login-path=tempsetting "$DB_NAME"

echo "CREATE INDEX hashindex ON fingerprints (hash1(27))" | mysql --login-path=tempsetting "$DB_NAME"
_error_check
#remove root config
mysql_config_editor remove --login-path=tempsetting


#get input for user creation
echo "This will create a user on the mm database"
if [ -z "$DB_NAME" ] ; then
echo "Please enter the name of target database"
read -r DB_NAME
fi
echo "Please enter the name of user to be created"
read -r USER_NAME
echo "Please enter the password for the new user"
read -r USER_PASSWORD
echo "Creating user at localhost"
USER_HOST="localhost"
echo "Please enter mysql root password"
mysql_config_editor set --login-path=tempsetting --host=localhost --user=root --password

#create user
echo "CREATE USER \""$USER_NAME"\"@\""$USER_HOST"\" IDENTIFIED BY \""$USER_PASSWORD"\"" | mysql --login-path=tempsetting
_error_check
echo "GRANT ALL PRIVILEGES ON "$DB_NAME".* TO \""$USER_NAME"\"@\""$USER_HOST"\"" | mysql --login-path=tempsetting
_error_check
echo "FLUSH PRIVILEGES" | mysql --login-path=tempsetting

#show commands to create sql login path
if [ "$USER_HOST" = "localhost" ] ; then
    db_host="localhost"
else
    db_host=$(ifconfig |grep inet | tail -n1 | cut -d ' ' -f2)
fi
echo -e "\033[1;103;95mTo finalize, run the following command on your user machine. NOTE You may wish to confirm your host IP address first!\033[0m"
echo -e "\033[1;103;95mmysql_config_editor set --login-path="$USER_NAME"_config --host="$db_host" --user="$USER_NAME" --password\033[0m"
echo -e "\033[1;103;95mFollowed by the user password: "$USER_PASSWORD"\033[0m"

echo ""
echo -e "\033[1;103;95mThen, use the following settings in mmconfig\033[0m"
echo -e "\033[1;103;95mDatabase Profile is: "$USER_NAME"_config\033[0m"
echo -e "\033[1;103;95mDatabase Name is: "$DB_NAME"\033[0m"
#remove root config
mysql_config_editor remove --login-path=tempsetting

echo "DBNAME=\"${DB_NAME}\"" > "${DBCONFIG}"
echo "DBLOGINPATH=\"${USER_NAME}_config\"" >> "${DBCONFIG}"