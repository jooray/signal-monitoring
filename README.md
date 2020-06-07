# signal-monitoring

This program is for simple server monitoring and notifications with signal-cli.
It's goal is to be able to run on supersimple servers, like NAS, raspberry pi,
home routers, etc.

## Setup

First, install and configure [signal-cli](https://github.com/AsamK/signal-cli)
(or replace script in notify function for different kind of notification).

Then modify script and configure your sending number, recipient number and
optionally path to java. I add PATH to signal-cli and java commands as well.

Then at the bottom of the script, configure ping checks, URL string match
checks and successful ssh (key) authentication.

**check_ping** takes one argument, which is the name of the server

**check_url** takes three arguments: "check identificator" (can be anything recognizable
that can be a part of filename, such as hostname), URL and string to look for on the web page.

**check_ssh** takes three arguments: username, hostname a optional port (otherwise it's 22).
Make sure that ssh key authentication is working, because it does not simply check for open
port, but if the authentication succeeds. It only needs to be able to run echo command, or
you can configure the shell to just print "ssh_connection_ok" on stdout. It does not need
to be able to execute any other commands.

The last **signal-cli** command just downloads all messages for this instance and
drops them. Use this if this script is the only user using this server to
ease up storage requirements for signal servers and make sure that it does not
store too much (encrypted) messages for you.

## Cron

Run it from cron or task scheduler of your OS. Please refer to the documentation
of your OS.

## Why this project

I wanted to be able to perform a simple monitoring for my hosted server from
my home NAS. Signal is what I read, so e-mail notifications won't do it,
I don't read e-mail that often.

The script sends one notification per hour, if the service is consistently down.
When it goes up again, it sends up notification.

## If you liked this script, donate

If you like this script, [support me by sending a small donation](https://juraj.bednar.io/en/support-me/)