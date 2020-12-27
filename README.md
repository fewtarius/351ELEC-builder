# 351ELEC-builder
A simple script to generate a build and post on discord.

## Requirements
The script expects google-drive-ocamlfuse to be installed and configured, and your google drive mountable on /mnt/gdrivefs.  It's strongly recommended to enable delete_forever_in_trash_folder in your google-drive-ocamlfuse configuration.

To integrate with Discord, create a webhook integration in the destination channel and configure the URL as "WD" in ~/.build_settings.

## Usage
Create ~/.build_settings with the following content:

SHARED      - Google Drive Shared URL
UPLOAD_PATH - Google Drive Upload Path
BOTNAME     - Discord "Bot" name..
MESSAGE     - Discord message prefix.
TOKEN       - Discord Webhook Token
WD          - 351ELEC Build Root

Add 351elec-builder to cron.d or crontab.

To specify an alternate configuration, pass the new configuration to be sourced as the only argument.
