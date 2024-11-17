# signal-monitoring

This program is for simple server monitoring and notifications with signal-cli, [matrix-commander](https://github.com/8go/matrix-commander), through LXMF ([Reticulum mesh network](https://reticulum.network/)), or [simplex-chat](https://github.com/simplex-chat/simplex-chat/blob/stable/docs/CLI.md).

It's goal is to be able to run on supersimple servers, like NAS, raspberry pi,
home routers, etc.

## Setup

First, if you want to use signal-cli, install and configure [signal-cli](https://github.com/AsamK/signal-cli) (or uncomment the right part in notify function for different kind of notification -
matrix-commander, LXMF-notify, or simplex-chat - see below).

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

**check_script** takes a check identificator as the first parameter and the rest are
executed (warning, no sanity checking, we expect no user input coming to this). If the script
returns an error status, it failed (exit status >0)

**attempts** tries a check more times before notifying. Good for checks that sometimes fail,
but it is not a big deal, if it works in a few seconds/minutes. attempts tries number_of_attempts
times, with sleep_between_attempts seconds between intervals (these are the first two arguments)
and the rest is just a normal check call.

The last **signal-cli** command just downloads all messages for this instance and
drops them. Use this if this script is the only user using this server to
ease up storage requirements for signal servers and make sure that it does not
store too much (encrypted) messages for you.

## Cron

Run it from cron or task scheduler of your OS. Please refer to the documentation
of your OS.

## Matrix support

I added Matrix protocol support, because Signal now sometimes asks for
CAPTCHAs and I would really like to get notifications even if Signal descides
it wants to ask for CAPTCHA.

Install [matrix-commander](https://github.com/8go/matrix-commander) using python. Login
with 

```
matrix-commander --login password # password is a string, not your password
```

It will ask you for the device name, I use server name, so I know where the notification
came from.

It will also ask you for the room name, it is best if it already created and has both
this user and the user that needs to access the messages in the room already.

Then verify your device keys with other device (such element):

```
matrix-commander --verify emoji
```

After you are done, move config and store to correct directories:

```
mkdir -p ~/.local/share/matrix-commander/ ~/.config/matrix-commander/
mv store ~/.local/share/matrix-commander/
mv credentials.json ~/.config/matrix-commander/
```

Try sending a message:

```
matrix-commander -m "Hello from Matrix commander"
```

The message will go to the default room you configured in the first place.

If you are done, make sure matrix-commander is in the path for the script and uncomment
the matrix-commander line in notify function (alternatively comment the two signal-cli
lines in the script - the one above matrix-commander and the receive at the end of the
script).

## LXMF / Reticulum / Sideband

Reticulum is immensly cool. It is a mesh network that is medium agnostic, encrypted
by default. The reason I am using it is that I want to be able to receive a notification
even if my internet connection is down. The network will find a way, for example through
LoRA. If my phone is online and I have more than one interface, it will find a way to deliver
the message to my phone by itself. So this is the most resilient way to deliver the
message that should work regardless on how the infrastructure works. If you are on home
wifi, it will even deliver it locally if autointerface is configured in reticulum.

It works by using [my command-line LXMF notify bot](https://github.com/jooray/lxmf-message).

You need to install and configure [Sideband](https://github.com/markqvist/Sideband) on your phone,
get the address. You can also use a propagation node, where the message is stored if you are not
online.

## simplex-chat

SimpleX is another cool messenger. You can run your own server, it is not
dependant on single infrastructure provider, anyone can run a node, but it is
highly secure.

We can use [command-line version](https://github.com/simplex-chat/simplex-chat/blob/stable/docs/CLI.md).
After installation, you need to choose a display name and connect to a user or group
that should receive notifications. Use the /c command to connect to a user, or the /g
command to connect to a group. After you are connected, write the nickname or group name
into the configuration file, prefixing it with @ for users or # for groups:

```
SIMPLEX_DESTINATION="@nickname"  # for users
```
or
```
SIMPLEX_DESTINATION="#groupname"  # for groups
```

If something does not work, the command that should work for sending to a user is:

```
simplex-chat -e '@nickname This is a test' -t 10
```

For sending to a group, use:

```
simplex-chat -e '#groupname This is a test' -t 10
```

## Why this project

I wanted to be able to perform a simple monitoring for my hosted server from
my home NAS. Signal is what I read, so e-mail notifications won't do it,
I don't read e-mail that often.

The script sends one notification per hour, if the service is consistently down.
When it goes up again, it sends up notification.

## If you liked this script, donate

If you like this script, [support me by sending a small donation](https://juraj.bednar.io/en/support-me/)
