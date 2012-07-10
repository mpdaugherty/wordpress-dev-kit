#!/bin/bash

# Temporarily save the old values so we can restore them after execution
SOURCE_TEMP=$SOURCE
DIR_TEMP=$DIR

SOURCE="${BASH_SOURCE[0]}"
# Go through all symlinks to find the ultimate location of the source file
while [ -h "$SOURCE" ] ; do SOURCE="$(readlink "$SOURCE")"; done
# Get an absolute path to the directory that contains this file
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

read -p "What is your host name? (e.g. the @xyz.com when you SSH) " HOSTNAME
read -p "What is your remote username? " USERNAME
read -p "Where is your SSH key file? " SSHKEY
read -p "What is the URL at which you will install this blog? (No http/s://) " URL
read -p "Who is your site's admin? " ADMIN

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
read -p "What is your desired MySQL DB Name? " DB_NAME
read -p "What is your desired DB user name?  " DB_USERNAME
read -p "What is your desired DB password?   " DB_PSWD

LOCAL_SQL="
create database $DB_NAME;
create user '$DB_USERNAME'@'localhost' identified by '$DB_PSWD';
GRANT ALL ON $DB_NAME.* to 'DB_USERNAME'@'localhost';
FLUSH PRIVILEGES;
"

echo $LOCAL_SQL > wp_setup_local_sql.sql

echo "Run this SQL (saved in wp_setup_local_sql.sql):"
cat wp_setup_local_sql.sql

# TODO: RUN THE SQL

# TODO: make wp-config.php from info


# Restore old values
SOURCE=$SOURCE_TEMP
DIR=$DIR_TEMP