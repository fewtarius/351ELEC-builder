#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2020-present Fewtarius

WD="${HOME}/repositories/351ELEC"
cd ${WD}
${HOME}/repositories/builder/builder \
  -b "main" \
  -e \
  -l \
  -m 'Build v@VERSION@ (@BUILDCOMMIT@, @BRANCH@ branch) is now available for installation.\n\nChanges since the last build:\n\n@CHANGELOG@\nDownload from @URL@ or update using the "daily" channel on your device' \
  -n "Build Bot" \
  -r "${WD}" \
  -p "${WD}" \
  -t "https://my_discord_token" \
  -u "https://updates.351elec.org/releases/daily" \
  -s "rsync -trluhv --delete --inplace --progress --stats ${WD}/release/* user@my_web_host:/var/www/html/releases/daily/$(date +%Y%m%d%S)"
