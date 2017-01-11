
<Get Oldest Vault - works due to naming convention (yyyymmdd) being sorted numerically>
    listOfVaults=$(aws glacier list-vaults --account-id - --query 'VaultList[].[VaultName]' | sort -n)
    archiveToDelete=$(echo $listOfVaults | awk '{ print $1 }')

    jobName=$(aws glacier initiate-job --account-id - --vault-name $archiveToDelete --job-parameters '{"Type": "inventory-retrieval"}')

    wait 12 hours ....

    <Reset Variables in case of restart check to see if variable is set>
    listOfVaults=$(aws glacier list-vaults --account-id - --query 'VaultList[].[VaultName]' | sort -n)
    archiveToDelete=$(echo $listOfVaults | awk '{ print $1 }')

<Get Job Number - needed only if reset // how to check if variable is set???>
    jobName=$(aws glacier list-jobs --account-id - --vault-name $archiveToDelete --query JobList[].JobId)

<needs testing ------ reset variables again? how long does getting job take? >

    sudo aws glacier get-job-output --account-id - --vault-name $archiveToDelete --job-id $jobName /var/www/html/resourcespace/output.txt

    archiveID=$(grep "(?<=ArchiveId\"\:\").*(?=\"\,\"ArchiveDescription)")   ???????

    sudo rm /var/www/html/resourcespace/output.txt



    aws glacier delete-archive --account-id - --vault-name vaultName?? --archive-id <value>


    aws glacier delete-vault --vault-name $archiveToDelete --account-id -