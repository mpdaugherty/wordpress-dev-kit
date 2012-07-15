#!/bin/bash

# Temporarily save the old values so we can restore them after execution
SOURCE_TEMP=$SOURCE
DIR_TEMP=$DIR

SOURCE="${BASH_SOURCE[0]}"
# Go through all symlinks to find the ultimate location of the source file
while [ -h "$SOURCE" ] ; do SOURCE="$(readlink "$SOURCE")"; done
# Get an absolute path to the directory that contains this file
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

read -p "What is your host name? (e.g. the @xyz.com when you SSH)\n  " HOSTNAME
read -p "What is your remote username?\n  " USERNAME
read -p "Where is your SSH key file?\n  " SSHKEY
read -p "What is the URL at which you will install this blog? (No http/s://)\n  " URL
read -p "Who is your site's admin?\n  " ADMIN

# With all that info, we can create a config.py file
cd $DIR/..
echo "
HOSTS = [\"$HOSTNAME\"]
USER  = \"$USERNAME\"
KEY   = \"$SSHKEY\"
URL   = \"$URL\"
ADMIN = \"$ADMIN\"
" > config.py

# We can also set up a local database for this site
read -p "What is your desired MySQL DB Name?\n  " DB_NAME
read -p "What is your desired DB user name?\n  " DB_USERNAME
read -p "What is your desired DB password?\n  " DB_PSWD

LOCAL_SQL="
create database $DB_NAME;
create user '$DB_USERNAME'@'localhost' identified by '$DB_PSWD';
GRANT ALL ON $DB_NAME.* to 'DB_USERNAME'@'localhost';
FLUSH PRIVILEGES;
"

echo $LOCAL_SQL > wp_setup_local_sql.sql

echo "\nYou need to run this SQL (saved in wp_setup_local_sql.sql):\n"
cat wp_setup_local_sql.sql

read -p "\nIf you'd like to execute this immediately, enter your MySQL root username (otherwise, enter nothing):\n  " DB_ROOT_USER
if [ $DB_ROOT_USER ]
then
    mysql -u $DB_ROOT_USER -p < wp_setup_local_sql.sql
fi


# Create a new wp-config file from the info from the user
cp test_wp/wp-config-sample.php test_wp/wp-config.php
sed -i '' "s/database_name_here/$DB_NAME" test_wp/wp-config.php
sed -i '' "s/username_here/$DB_USERNAME" test_wp/wp-config.php
sed -i '' "s/password_here/$DB_PSWD" test_wp/wp-config.php
bin/update_wp_salts.py

# Done!
echo '\nPlease visit '`pwd`'/temp_wp/wp-admin in your web browser to complete installation and install your custom theme'

# Restore old values for variables
SOURCE=$SOURCE_TEMP
DIR=$DIR_TEMP