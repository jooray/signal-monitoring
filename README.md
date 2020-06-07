# signal-monitoring

This program is for simple server monitoring and notifications with signal-cli.
It's goal is to be able to run on supersimple servers, like NAS, raspberry pi,
home routers, etc.

## Setup

First, install and configure [signal-cli](https://github.com/AsamK/signal-cli)
(or replace script in notify function for different kind of notification).

Then modify script and configure your sending number, recipient number and
optionally path to java. I add PATH to signal-cli and java commands as well.

Then at the bottom of the script, configure ping checks and URL string match
checks.

check_ping takes one argument, which is the name of the server

check_url takes three arguments: "check identificator" (can be anything recognizable that can be a part of filename, such as hostname), URL and string to look for on the web page.

The last signal-cli command just downloads all messages for this instance and
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