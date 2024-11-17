#!/bin/bash
# if you need to add something to path:
#PATH=$PATH:/path/to/java:/path/to/signal-cli
# for some cases you should explicitly specify JAVA_HOME in
# order for signal-cli to work
#export JAVA_HOME=/var/packages/Java8/target/j2sdk-image/jre

### For Signal
# username of the sending entity (phone number in international format)
SIGNAL_USER="+1123123123123"

# phone number of the user that receives the notification
NOTIFY_NUMBER="+132132132132"


### For LXMF-Notify (reticulum, sideband)
LXMF_DESTINATION="12312312312312312312312312312312"
# display name of your identity
LXMF_NAME="LXMF bot signal-monitoring"
# propagation node (optional)
LXMF_PROPAGATION="32112312312312312312312312312312"

### For simplex-chat command-line utility
# Nickname of already connected user (use /c) or group (use /g)
# Prefix user with @ and group with #

SIMPLEX_DESTINATION="@nickname"

# Time to wait for Simplex - this needs to be long enough to send the message to
# the relay. See: https://github.com/simplex-chat/simplex-chat/issues/5196
# The command is sent to background, so it won't block processing
SIMPLEX_WAIT=10

# now go to the notify function below, choose which notification mechanism
# to use.

# Then go bottom of the script and specify the checks

export LC_ALL="en_US.utf8" # This makes emojis work - an UTF-8 locale
mkdir -p ~/.signal-monitoring && cd ~/.signal-monitoring

##### CHECKING ENGINE

# just a sane global default
notify_on_failures=1

function log {
	echo $(date "+%Y-%m-%d %H:%M:%S: ") "$1" >> ~/.signal-monitoring/log
}

# arguments: notify_text
function notify {
    # Signal CLI
	signal-cli -a "${SIGNAL_USER}" send "${NOTIFY_NUMBER}" -m "$1" > /dev/null
    # Matrix
    #matrix-commander --log-level ERROR ERROR -m "$1"
    # LXMF / Reticulum / Sideband
    #echo "$1" | LXMF-NotifyBot.py "${LXMF_DESTINATION}" "${LXMF_NAME}" "${LXMF_PROPAGATION}" > /dev/null
    # SimpleX
    #(simplex-chat -e "${SIMPLEX_DESTINATION} ${1}" -t ${SIMPLEX_WAIT} > /dev/null) &
	log "Sending notification ${1}"
}

# arguments: check_name description
function check_passed {
	check_name="$1"
	description="$2"
	check_filename="${check_name}-error"

	log "check_passed ${check_name} ${description}"

	if [ -f "${check_filename}" ]
		then
			rm -f "${check_filename}"
			notify "✅ ${description}"
		fi

  return 0
}

# arguments: check_name description
function check_failed {
	check_name="$1"
	description="$2"
	check_filename="${check_name}-error"

	log "check_failed ${check_name} ${description}"

	FOUND=$(find ~/.signal-monitoring -mmin -60 -name "${check_filename}" -not -empty -print)
	if [ -z "$FOUND" ]
	  then # we don't have recent notification (60 minutes)
    if [ $notify_on_failures == 1 ]
        then
		        echo "${description}" > "${check_filename}"
        		notify "❌ ${description}"
        else
            log "check_failed notification not sent, will retry first"
        fi
	  fi

  return 1
}

# arguments: attempts number_of_attempts sleep_time check_script_to_call check_arguments
# example attempts 3 60 check_ping my-first.server.com
function attempts {
    number_of_attempts="$1"
    sleep_time="$2"
    check_script_to_call="$3"
    # check_arguments are $4 and on

    for attempt in $(seq 1 ${number_of_attempts})
    do
        if [ "${attempt}" == "${number_of_attempts}" ]
        then
            notify_on_failures=1
        else
            notify_on_failures=0
        fi

        if "$check_script_to_call" "${@:4}"
        then
            notify_on_failures=1
            return 0
        else
            if [ "${notify_on_failures}" != 1 ]
                then
                    log "Will retry in ${sleep_time}s"
                    sleep $sleep_time
                fi
        fi
    done
}

##### SERVICE CHECK IMPLEMENTATIONS

# argument: hostname
function check_ping {
		server="$1"
		if ping -c 5 -q $server > /dev/null 2>&1
			then
				check_passed "${server}-ping" "${server} ping is up"
			else
				check_failed "${server}-ping" "${server} ping is not responding"
			fi
}

# arguments: check_name url content_to_look_for
function check_url {
		check_name="$1"
		url="$2"
		content_to_look_for="$3"
		if wget --server-response=off -q -O - "${url}" | grep "${content_to_look_for}" > /dev/null 2>&1
			then
				check_passed "${check_name}-url" "${check_name} UP: ${url} now contains ${content_to_look_for}"
			else
				check_failed "${check_name}-url" "${check_name} DOWN: ${url} does not contain ${content_to_look_for}"
			fi
}

# arguments: check_name command
# warning: no sanitization
function check_script {
		check_name="$1"
    shift
		OUTPUT=$( "$@" 2>&1)
    ERR=$?
		if [ $ERR -eq 0 ]
			then
				check_passed "${check_name}" "${check_name} UP: $OUTPUT"
			else
				check_failed "${check_name}" "${check_name} DOWN: $OUTPUT"
			fi
}

# argument: username hostname port
function check_ssh {
    username="$1"
    hostname="$2"
    port="${3:-22}"

    status=$(ssh -o BatchMode=yes -o ConnectTimeout=5 ${username}@${hostname} -p ${port} echo ssh_connection_ok 2>&1)

    if [[ "${status}" == "ssh_connection_ok" ]] ; then
			check_passed "${username}-${hostname}-${port}-ssh" "${username}@${hostname}:${port} SSH is up"
    elif echo "${status}" | grep -q "Permission denied" ; then
			check_failed "${username}-${hostname}-${port}-ssh" "${username}@${hostname}:${port} SSH returned permission denied: ${status}"
    else
			check_failed "${username}-${hostname}-${port}-ssh" "${username}@${hostname}:${port} SSH is down: ${status}"
    fi
}


# here are the checks

# check pings
check_ping my-first.server.com
attempts 3 60 check_ping my-second.server.com

check_url my-first.server.com "https://my-first.server.com/url/index.html" "Welcome to My First Server"
attempts 2 30 check_url my-third.server.com "https://my-third.server.com/index.html" "Welcome to My Third Server"

check_ssh "johnpb27" "my-ssh.server.com" 22

check_script "alliswell" "/usr/local/bin/is-all-well"

# Leave this if you don't use signal-cli outside of this script,
# otherwise comment out, see readme
signal-cli -a $SIGNAL_USER receive > /dev/null 2>&1
