# builder
A simple script to generate a build from a repository checkout and post a notice on discord when the build is available in an update channel.

## Requirements
All of the requirements to build 351ELEC should be satisfied before using this script.  The script expects to rsync the binaries to a web host, be sure that there is an ssh public key on the target and ssh-agent is caching the passphrase if your key is configured with one.

To integrate with Discord, create a webhook integration in the destination channel and pass it as a command argument.

## Usage
Run ./builder -h for help.
