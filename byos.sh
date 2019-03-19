#! /usr/bin/env bash

# this script is intended to be invoked from ensure_web.sh
# env vars are sourced from .env there

webapp_name=${WEB_NAME}
webapp_group=${GROUP_NAME}

storage_account_name=${STORAGE_ACCOUNT_NAME}
storage_account_group=${GROUP_NAME}
storage_account_location=${GROUP_LOCATION}
storage_container_name=${STORAGE_CONTAINER_NAME}
storage_mount_path=${STORAGE_MOUNT_PATH}

storage_id=$(az storage account show \
  --name ${storage_account_name} \
  --resource-group ${storage_account_group} \
  --output tsv --query id)
if [[ -z "${storage_id}" ]]; then
  storage_id=$(az storage account create \
    --name ${storage_account_name} \
    --resource-group ${storage_account_group} \
    --location ${storage_account_location} \
    --output tsv --query id)
fi
>&2 echo "ensured storage account: [${storage_id}]"

storage_account_key=$(az storage account keys list \
  --account-name ${storage_account_name} \
  --resource-group ${storage_account_group} \
  --output tsv --query '[0].value')

byos_name=web-app-storage
byos_id=$(az webapp config storage-account list \
  --name ${webapp_name} \
  --resource-group ${webapp_group} \
  --output tsv --query '[0].name')
if [[ -z "${byos_id}" ]]; then
  byos_id=$(az webapp config storage-account add \
    --name ${webapp_name} \
    --resource-group ${webapp_group} \
    --custom-id ${byos_name} \
    --account-name $storage_account_name \
    --access-key $storage_account_key \
    --share-name $storage_container_name \
    --storage-type AzureBlob \
    --mount-path ${storage_mount_path})
fi
>&2 echo "ensured byos storage: [${byos_id}]"
