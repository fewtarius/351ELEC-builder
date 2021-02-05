#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2020-present Fewtarius

# ~/.build_settings contents
# SHARED      - Shared URL
# UPLOAD_PATH - Upload Path
# SERVER      - User at Host
# BOTNAME     - Discord "Bot" name..
# BRANCH      - Git branch to build from
# TOKEN       - Discord Webhook Token
# WD          - 351ELEC Build Root

BUILD_SETTINGS="${HOME}/.build_settings"

if [ -z "${1}" ]
then
  source ${BUILD_SETTINGS}
  if [ ! $? == 0 ]
  then
    echo "Could not source ${BUILD_SETTINGS}"
    exit 1
  fi
else
  source ${1}
  if [ ! $? == 0 ]
  then
    echo "Could not source ${1}"
    exit 1
  fi
fi

cd ${WD}

git fetch
git checkout ${BRANCH} || exit 1
git pull || exit 1
LAST_BUILD=$(cat .lastbuild)
COMMIT=$(git log | head -n 1 | awk '{print $2}' | cut -c -7)
if [ ! "${COMMIT}" == "${LAST_BUILD}" ]
then
  YESTERDAY=$(date --date "yesterday" +%Y%m%d)
  DATE=$(date +%Y%m%d)
  make clean || exit 1
  make world
  if [ $? == 0 ]
  then
    . $(find build.351ELEC-RG351P.aar*/image/system -name os-release)
    if [ -d "${UPLOAD_PATH}/${YESTERDAY}" ] && [ -n "${UPLOAD_PATH}" ]
    then
      ssh ${SERVER} rm -rf ${UPLOAD_PATH}/${YESTERDAY} 2>/dev/null
    fi
    if [ -z "${1}" ]
    then
      TAG=${DATE}
    else
      TAG=${VERSION}
    fi
    rsync -trluhv --delete --inplace --progress --stats ${WD}/release/* ${SERVER}:${UPLOAD_PATH}/${DATE}
    if [ $? == 0 ]
    then
      make clean
      curl -X POST -H "Content-Type: application/json" -d '{"username": "'${BOTNAME}'", "content": "'"Build"' '${NAME}'-'${BRANCH}'-'${TAG}' ('${COMMIT}') is now available.\n<'${SHARED}'>"}' "${TOKEN}"
      echo ${COMMIT} >.lastbuild
    fi
  fi
fi
