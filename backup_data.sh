#!/usr/bin/env bash

# Backup data from the fcatalog data container.

# Set abort on error:
set -e

prog_name=`basename $0`

if [ "$#" -gt "1" ]; then
	echo "Usage:" 
	echo "$prog_name"
	echo "or"
	echo "$prog_name dest_file"
	exit
fi

# Check if fcatalog_server_cont is running. If it does,
# we will abort. We don't want to read the data while the server
# container is running.
nlines_server=`docker ps | grep fcatalog_server_cont | wc -l`
if [ "$nlines_server" -gt "0" ]
	then echo "fcatalog_server_cont is still running! Aborting data backup." && \
		exit
fi

echo "Creating backup..."

BACK_DIR="backup_temp"

mkdir -p ./${BACK_DIR}

# Backup the data from the fcatalog server
# by copying it to backup_temp directory on the host:
# Note: The p flag for cp preserves ownership.
docker run --name fcatalog_data_backup_cont \
	--volumes-from fcatalog_data_cont \
	-v $(readlink -f $BACK_DIR):/backup \
        fcatalog_data \
	sh -c "\
        cp -Rp /var/lib/fcatalog/. /backup/"

# Clean up docker container:
docker rm -f fcatalog_data_backup_cont


# Create a tar archive (With the current date):

if [ "$#" -eq "1" ]; then
	# Filename (full path) is chosen as argument:
	back_filename=$1
else
	# We are going to save into ./backups directory:
	mkdir -p ./backups
	# Filename is generated by time:
	now=$(date +%Y_%m_%d_%H_%M_%S)
	back_filename="./backups/backup_${now}.tar"
fi

# Put all data to back up into a tar file:
tar -cvf ${back_filename} $BACK_DIR > /dev/null

# Remove the temporary backups folder:
rm -Rf $BACK_DIR

echo "Backup saved at ${back_filename}"

# Unset abort on error:
set +e