#!/bin/bash

TRACTOR_ENGINE_URL="animtractor"
# the script needs credentials for a user with wrangler permissions so that it can eject tasks
TRACTOR_WRANGLER_UN="wrangler"
TRACTOR_WRANGLER_PW=""

force_state=2
# Check if force argument given
if [[ "$#" -ne 0 ]]; then
  if [[ "$1" == "on" ]]; then
    force_state=0
  elif [[ "$1" == "off" ]]; then
    force_state=1
  fi
fi

# Log in to animtractor
if [[ -z "$TRACTOR_WRANGLER_PW"]]; then   # if password is empty
    login=$(curl -s "${TRACTOR_ENGINE_URL}/Tractor/monitor?q=login&user=${TRACTOR_WRANGLER_UN}")
else
    login=$(curl -s "${TRACTOR_ENGINE_URL}/Tractor/monitor?q=login&user=${TRACTOR_WRANGLER_UN}&c=${TRACTOR_WRANGLER_PW}")
fi

info=$(curl -s "127.0.0.1:9005/blade/status")

host=$(echo "$login" | jq -r .host)
hnm=$(echo "$info" | jq -r .hnm)
tsid=$(echo "$login" | jq -r .tsid)

## Check if NIMBY should be enabled
if    [[ "$force_state" -ne 1 ]]      \
   && [[ $(w -sh | wc -l) -ne 0 ]]  \
   || [[ "$force_state" -eq 0 ]]; then
  # Turn NIMBY on and eject existing tasks
  echo "Turning NIMBY on"
  curl -s "127.0.0.1:9005/blade/ctrl?nimby=1"
  sleep 1
  echo "Eject any running tasks"
  curl -s "animtractor/Tractor/queue?q=ejectall&blade=${hnm}/${host}&tsid=${tsid}"
else
  echo "Turning NIMBY off"
  curl -s "127.0.0.1:9005/blade/ctrl?nimby=0"
fi
