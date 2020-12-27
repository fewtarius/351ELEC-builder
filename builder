#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2020-present Fewtarius

# ~/.build_settings contents
# SHARED      - Google Drive Shared URL
# UPLOAD_PATH - Google Drive Upload Path
# BOTNAME     - Discord "Bot" name..
# MESSAGE     - Discord message prefix.
# TOKEN       - Discord Webhook Token
# WD          - 351ELEC Build Root

cd ${WD}

COMMIT=$(git log | head -n 1 | awk '{print $2}' | cut -c -10)
YESTERDAY=$(date --date "yesterday" +%Y%m%d)
DATE=$(date +%Y%m%d)

if [ -z "${1}" ]
then
  source ~/.build_settings || exit 1
  cd ${WD}
  TAG=${DATE}
else
  source ${1}
  if [ ! $? == 0 ]
  then
    echo "Could not source ${1}"
    exit 1
  fi
  cd ${WD}
  TAG=$(cat packages/351elec/config/EE_VERSION)
fi

(mount | grep [g]drivefs) || google-drive-ocamlfuse /mnt/gdrivefs
LAST_BUILD=$(cat .lastbuild)
if [ ! "${COMMIT}" == "${LAST_BUILD}" ]
then
  make clean
  make world
  if [ $? == 0 ]
  then
    . $(find build.351ELEC-RG351P.aar* -name os-release)
    if [ -d "${UPLOAD_PATH}/${YESTERDAY}" ] && [ -n "${UPLOAD_PATH}" ]
    then
      rm -rf ${UPLOAD_PATH}/${YESTERDAY} 2>/dev/null
    fi
    rsync -trluhv --delete --inplace --progress --stats ${WD}/release/* ${UPLOAD_PATH}/${DATE}
    curl -X POST -H "Content-Type: application/json" -d '{"username": "'${BOTNAME}'", "content": "${MESSAGE} '${NAME}'-'$TAG' ('$COMMIT') is now available.\n<'${SHARED}'>"}' "${TOKEN}"
    echo ${COMMIT} >.lastbuild
  fi
fi
