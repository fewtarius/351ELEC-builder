#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2020-present Fewtarius

function show_help() {
  cat <<EOF

Usage: builder [OPTIONS]
A tool to build 351ELEC and replicate the distribution to a web farm.

Arguments:
  -b Branch to check out for building.
  -c Clean the build root environment.
  -f Force build.
  -h This help message.
  -l Perform a git pull before building.
  -n The friendly bot name for Discord.
  -r The source code build root.
  -t Discord weburl / token.
  -p Working directory of this script.
  -u Where users can download the uploaded content.
  -s The sync command to push the completed build.
  -x Build but do not sync or notify.
EOF
  exit 1
}

### Process arguments
while getopts "b:m:n:p:r:s:t:u:cefhlx" opt
do
  case $opt in
  b )
    # Git branch
    BRANCH="${OPTARG}"
  ;;
  c )
    # Git clean
    CLEAN=true
  ;;
  e )
    # Git reset
    RESET=true
  ;;
  f )
    FORCE=true
  ;;
  h )
    show_help
  ;;
  l )
    # Git pull
    PULL=true
  ;;
  m )
    # Discord message
    MESSAGE="${OPTARG}"
  ;;
  n )
    # "bot" name
    BOTNAME="${OPTARG}"
  ;;
  r )
    # Build root
    ROOT="${OPTARG}"
  ;;
  t )
    # Discord token
    TOKEN="${OPTARG}"
  ;;
  p )
    # Working directory
    WD="${OPTARG}"
  ;;
  s )
    # rsync command
    SYNC="${OPTARG}"
  ;;
  u )
    # Download URL
    URL="${OPTARG}"
  ;;
  x )
    # Don't sync
    NOSYNC=true
  ;;
  esac
done

if [ ! "${WD}" ]
then
  WD="$(pwd)"
fi

if [ ! -d "${WD}" ]
then
  mkdir -p "${WD}"
fi

cd "${WD}"

if [ ! -d "${WD}/logs" ]
then
  mkdir -p "${WD}/logs"
fi

LOG="${WD}/logs/$(date +%s).log"

### Function library

function log() {
  if [ ! "${2}" ]
  then
    NOTICE="INFO"
  else
    NOTICE="${2}"
  fi
  echo "$(date +%s): ${NOTICE} ${1}" >>${LOG}
}

function error() {
  log "${1}" ERROR
  rm -f "${WD}/.run"
  exit 1
}

function notify_discord() {
  MESSAGE=${1}
  curl -X POST \
    -H "Content-Type: application/json" \
    --data-binary "@/tmp/message.txt" \
    "${TOKEN}" &>> ${LOG}
}

function clean() {
  make clean  &>> ${LOG}
  if [ ! $? == "0" ]
  then
    error "Unable to clean build environment, aborting."
  else
    log "Build environment cleanup successful."
  fi
}

function checkout() {
  git checkout ${1}  &>> ${LOG}
  if [ ! $? == "0" ]
  then
    error "Unable to checkout branch ${1}"
  else
    log "Checked out branch ${1}"
  fi
}

function last_commit(){
  LASTCOMMIT=$(git rev-parse HEAD)
  log "Last commit: ${LASTCOMMIT}"
  if [ "${1}" == "short" ]
  then
    echo -n ${LASTCOMMIT:0:7}
  fi
  echo -n ${LASTCOMMIT}
}

function stop_build() {
  local PID COMMIT
  source "${WD}/.run"
  log "Found previous build ${PID} - ${COMMIT}"
  DEADORALIVE="$(ps ${PID} >/dev/null 2>&1)"
  if [ "$?" == 0 ]
  then
    if [ ! "${PID}" == "$$" ]
    then
      log "Killing ${PID}, $$"
      kill -SIGKILL -- ${PID} &>> ${LOG}
    fi
  else
    log "Stale run detected (${PID}, $$), cleaning up."
    rm -f "${WD}/.run"
  fi
}

# Main screen turn on.
# --------------------------------------------------------

echo "Build started at $(date +%s)" &> ${LOG}

cat <<EOF >> ${LOG}
BRANCH="${BRANCH}"
ROOT="${ROOT}"
TOKEN="${TOKEN}"
WD="${WD}"
SYNC="${SYNC}"
URL="${URL}"
EOF

### If another build process starts and kills us,
### clean up and kill all of our children.
trap "rm ${WD}/.run && kill -SIGKILL -$$" SIGKILL &>> ${LOG}

### Make sure we're building on the appropriate branch.
### If there is no branch defined, don't do anything.
if [ "${BRANCH}" ]
then
  git fetch  &>> ${LOG}
  checkout "${BRANCH}"
fi

### Clean out the build root if necessary
if [ "${CLEAN}" == true ]
then
  log "Cleaning the buildroot."
  clean
fi

### Do a git reset to undo any automated/manual changes
if [ "${RESET}" == true ]
then
  log "Performing a repository hard reset"
  git reset --hard  &>> ${LOG}
  if [ ! $? == "0" ]
  then
    error "Unable to reset the repository, aborting."
  else
    log "Reset successfull."
  fi
fi

### Pull the latest commits
if [ "${PULL}" == true ]
then
  log "Pulling the latest commits from github."
  git pull  &>> ${LOG}
  if [ ! $? == "0" ]
  then
    error "Unable to pull from source system, aborting."
  else
    log "Pull successfull."
  fi
fi

BUILDCOMMIT=$(last_commit)
PREVBUILD=$(cat ${WD}/.prevbuild 2>/dev/null)

if [ ! "${BUILDCOMMIT}" == "${PREVBUILD}" ] || [ "${FORCE}" == true ]
then
  COUNT=0
  while [ -f "${WD}/.run" ]
  do
    COUNT=$(( $COUNT + 1 ))
    if [ "${COUNT}" -ge 10 ]
    then
      error "Unable to stop previous build, aborting."
    fi
    log "Stopping previous build."
    stop_build
    log "Previous build stopped."
    sleep 5
  done
  cat <<EOF >"${WD}/.run"
PID=$$
COMMIT=${BUILDCOMMIT}
EOF
  log "Building the distribution."
  make world &>> ${LOG}
  if [ ! $? == 0 ]
  then
    error "Unable to build world, aborting."
  fi

  source distributions/351ELEC/version
  VERSION="${LIBREELEC_VERSION}"

  if [ ! "${NOSYNC}" == true ]
  then  
    log "Running sync command: ${SYNC}"
    ${SYNC} &>> ${LOG}
    if [ ! $? == 0 ]
    then
      error "Unable to complete sync, aborting."
    else
      log "Sync completed."
    fi

    TMPLOG=$(git log --oneline ${PREVBUILD}..${BUILDCOMMIT} >/tmp/gitlog)
    while IFS= read -r line
    do
      CHANGELOG="${CHANGELOG}${line}\n"
    done </tmp/gitlog

    rm -f /tmp/gitlog

    ### Replace the variables in the discord notification before sending.
    MESSAGE="$(echo ${MESSAGE} | sed 's#@VERSION@#'${VERSION}'#g')"
    MESSAGE="$(echo ${MESSAGE} | sed 's#@BUILDCOMMIT@#'${BUILDCOMMIT:0:7}'#g')"
    MESSAGE="$(echo ${MESSAGE} | sed 's#@BRANCH@#'${BRANCH}'#g')"
    MESSAGE="$(echo ${MESSAGE} | sed 's#@URL@#'${URL}'#g')"

    ### Escape characters that invalidate the json
    MESSAGE="$(echo ${MESSAGE} | sed 's#"#\\"#g')"

    cat <<EOF >/tmp/message.txt
{"username": "${BOTNAME}","content": "${MESSAGE}\n\nCommits since last build:\n\n\`\`\`${CHANGELOG}\`\`\`"}
EOF

    log "Notifying discord."
    notify_discord "${MESSAGE}" "${TOKEN}"
  fi
fi

echo -n "${BUILDCOMMIT}" >${WD}/.prevbuild
rm -f "${WD}/.run"

# --------------------------------------------------------
