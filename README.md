# builder
A simple script to generate a build from a repository checkout and post a notice on discord when the build is available in an update channel.

## Requirements
All of the requirements to build 351ELEC should be satisfied before using this script.  The script expects to rsync the binaries to a web host, be sure that there is an ssh public key on the target and ssh-agent is caching the passphrase if your key is configured with one.

To integrate with Discord, create a webhook integration in the destination channel and configure the URL as "TOKEN" in ~/.build_settings.

## Usage
Create ~/.build_settings with the following content.  Use KEY=value format.
```
SHARED      - Shared URL
UPLOAD_PATH - Upload Path
SERVER      - User at Host
BOTNAME     - Discord "Bot" name..
MESSAGE     - Discord message prefix.
TOKEN       - Discord Webhook Token
WD          - 351ELEC Build Root```
Add builder to cron.d or crontab.

To specify an alternate configuration, pass the new configuration to be sourced as the only argument.
