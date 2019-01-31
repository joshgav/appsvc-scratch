#!/usr/bin/env bash

## prolog
set -o errexit
__filename="${BASH_SOURCE[0]}"
__dirname=$(cd "$(dirname "${__filename}")" && pwd)
__root=${__dirname}
if [[ -f "${__root}/.env" ]]; then source "${__root}/.env"; fi
source "${__dirname}/util/helpers.sh"
export -f ensure_group  # from rm_helpers.sh, make available to children
## end prolog

az account set --subscription $SUBSCRIPTION_NAME

group_id=$(ensure_group $GROUP_NAME $GROUP_LOCATION)
echo "ensured group [${group_id}]"

### ensure appservice plan
plan_id=$(az appservice plan show \
  --name $PLAN_NAME \
  --resource-group $GROUP_NAME \
  --query 'id' --output 'tsv')
if [[ -z $plan_id ]]; then
  plan_id=$(az appservice plan create \
              --name $PLAN_NAME \
              --resource-group $GROUP_NAME \
              --is-linux \
              --location $PLAN_LOCATION \
              --sku $PLAN_SKU \
              --query id --output tsv)
fi
echo "ensured plan [${plan_id}]"

### ensure web
web_id=$(az webapp show \
  --name $WEB_NAME \
  --resource-group $GROUP_NAME \
  --query 'id' --output tsv)
if [[ -z $web_id ]]; then
  web_id=$(az webapp create \
            --name $WEB_NAME \
            --resource-group $GROUP_NAME \
            --plan $plan_id \
            --runtime $WEB_RUNTIME \
            --query id --output tsv)
fi
echo "ensured web [${web_id}]"

### enable logging
az webapp log config \
  --ids $web_id \
  --docker-container-logging filesystem \
  --level information 1> /dev/null
echo "enabled logging for web [${web_id}]"

### switch to Oryx builder
# az webapp config appsettings set \
#   --ids $web_id \
#   --settings "ENABLE_ORYX_BUILD=true" 1> /dev/null
# echo "switched to Oryx build"

### connect to git repo
if [[ "$CONNECT_REPO" == "true" ]]; then
  az webapp deployment source config \
    --ids $web_id \
    --repo-url $GIT_REPO \
    --branch 'master' \
    --git-token $GIT_TOKEN \
    --repository-type externalgit 1> /dev/null
  echo "connected git repo"
fi
