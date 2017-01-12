#!/usr/bin/env bash
#Monday (7pm) bp1
#Tuesday (7pm) bp2
#Wednesday (7pm) bp3
#Thursday (7pm) bp4
#Friday (7pm) bp5
#Saturday (7pm) bp6

#########################################################################################################
#bp1 dumps sql db into filestore folder, then zips filestore folder (initial config (for salts) included)
mysqldump -u root -p My54Streetmysql -u root -p resourcespace > backup.sql --all-databases | gzip> /var/www/html/resourcespace/filestore/mysqldb_`date +%F`.sql.gz
sudo zip -r /var/www/html/resourcespace/backup/filestore.zip /var/www/html/resourcespace/filestore

########################################################################################################
#bp2 creates a unique glacier vault then uploads the previously zipped folder
vaultName=$(date "+%y%m%d")

aws glacier create-vault --vault-name $vaultName --account-id -

aws glacier upload-archive --account-id - --vault-name $vaultName --body /var/www/html/resourcespace/backup/filestore.zip > archiveID.json

########################################################################################################
#bp3 removes local backup files (for next run) and initiates job to get oldest vault archive info
sudo rm /var/www/html/resourcespace/backup/filestore.zip

mutt -s "Check Archive Status" -a /var/www/html/resourcespace/backup/message.txt -- douglas.bluff@austincc.edu < ../../../../tmp/message.txt

listOfVaults=$(aws glacier list-vaults --account-id - --query 'VaultList[].[VaultName]' | sort -n)

archiveToDelete=$(echo $listOfVaults | awk '{ print $1 }')

jobName=$(aws glacier initiate-job --account-id - --vault-name $archiveToDelete --job-parameters '{"Type": "inventory-retrieval"}')

########################################################################################################
#bp4 gets the results of the job as a json file to be parsed (cannot be combined with bp5 due to time limitation imposed by glacier
listOfVaults=$(aws glacier list-vaults --account-id - --query 'VaultList[].[VaultName]' | sort -n)

archiveToDelete=$(echo $listOfVaults | awk '{ print $1 }')

sudo aws glacier get-job-output --account-id - --vault-name $archiveToDelete --job-id $jobName /var/www/html/resourcespace/backup/output.json

#########################################################################################################
#bp5 parses the previously acquired json file and uses the information to delete the oldest archive, then deletes the json file (for next run)
listOfVaults=$(aws glacier list-vaults --account-id - --query 'VaultList[].[VaultName]' | sort -n)

archiveToDelete=$(echo $listOfVaults | awk '{ print $1 }')

archiveID=$(grep -Po '(?<=ArchiveId":")(.*?)(?=",")' /var/www/html/resourcespace/backup/output.json)

aws glacier delete-archive --account-id - --vault-name $archiveToDelete --archive-id $archiveID

sudo rm /var/www/html/resourcespace/backup/output.json

#########################################################################################################
#bp6 deletes the oldest vault and sends a message to remind an administrator to ensure the backups are functioning correctly. The email will be removed once a PHP script maintains inventory of vaults (todolist)
aws glacier delete-vault --vault-name $archiveToDelete --account-id -

mutt -s "Archive Deleted" -a /var/ww/html/resourcespace/backup/message2.txt -- douglas.bluff@austincc.edu < ../../../../tmp/message.txt
