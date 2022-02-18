#!/bin/bash
# if you need to add something to path:
#PATH=$PATH:/path/to/java:/path/to/signal-cli
# for some cases you should explicitly specify JAVA_HOME in
# order for signal-cli to work
#export JAVA_HOME=/var/packages/Java8/target/j2sdk-image/jre

# username of the sending entity (phone number in international format)
SIGNAL_USER="+1123123123123"

# phone number of the user that receives the notification
NOTIFY_NUMBER="+132132132132"

# now go to the bottom of the script and specify the checks

mkdir -p ~/.signal-monitoring && cd ~/.signal-monitoring

function log {
	echo $(date "+%Y-%m-%d %H:%M:%S: ") "$1" >> ~/.signal-monitoring/log
}

# arguments: notify_text
function notify {
	echo "$1" | signal-cli -u ${SIGNAL_USER} send $NOTIFY_NUMBER > /dev/null
	log "Sending notification ${1}"
}

# arguments: check_name description
function check_passed {
	check_name=$1
	description=$2
	check_filename="${check_name}-error"

	log "check_passed ${check_name} ${description}"

	if [ -f ${check_filename} ]
		then
			rm -f $check_filename
			notify "✅ ${description}"
		fi
}

# arguments: check_name description
function check_failed {
	check_name=$1
	description=$2
	check_filename="${check_name}-error"

	log "check_failed ${check_name} ${description}"

	FOUND=`find ~/.signal-monitoring -mmin -60 -name ${check_name}-error -not -empty -print`
	if [ -z "$FOUND" ]
	  then # we don't have recent notification (60 minutes)
		echo "${description}" > "${check_filename}"
		notify "❌ ${description}"
	  fi
}


# argument: hostname
function check_ping {
		server=$1
		if ping -c 5 -q $server > /dev/null 2>&1
			then
				check_passed ${server}-ping "${server} ping is up"
			else
				check_failed ${server}-ping "${server} ping is not responding"
			fi
}

# arguments: check_name url content_to_look_for
function check_url {
		check_name=$1
		url=$2
		content_to_look_for=$3
		if wget -q -O - "$url" | grep "$content_to_look_for" > /dev/null 2>&1
			then
				check_passed ${check_name}-url "${check_name} UP: ${url} now contains ${content_to_look_for}"
			else
				check_failed ${check_name}-url "${check_name} DOWN: ${url} does not contain ${content_to_look_for}"
			fi
}

# arguments: check_name command
# warning: no sanitization and script
function check_script {
		check_name=$1
    shift
		OUTPUT=$( "$@" 2>&1)
    ERR=$?
		if [ $ERR -eq 0 ]
			then
				check_passed ${check_name} "${check_name} UP: $OUTPUT"
			else
				check_failed ${check_name} "${check_name} DOWN: $OUTPUT"
			fi
}

# argument: username hostname port
function check_ssh {
    username=$1
    hostname=$2
    port="${3:-22}"

    status=$(ssh -o BatchMode=yes -o ConnectTimeout=5 ${username}@${hostname} -p ${port} echo ssh_connection_ok 2>&1)

    if [[ $status == "ssh_connection_ok" ]] ; then
			check_passed ${username}-${hostname}-${port}-ssh "${username}@${hostname}:${port} SSH is up"
    elif echo $status | grep -q "Permission denied" ; then
			check_failed ${username}-${hostname}-${port}-ssh "${username}@${hostname}:${port} SSH returned permission denied: ${status}"
    else
			check_failed ${username}-${hostname}-${port}-ssh "${username}@${hostname}:${port} SSH is down: ${status}"
    fi
}


# here are the checks

# check pings
check_ping my-first.server.com
check_ping my-second.server.com

check_url my-first.server.com "https://my-first.server.com/url/index.html" "Welcome to My First Server"
check_url my-third.server.com "https://my-third.server.com/index.html" "Welcome to My Third Server"

check_ssh "johnpb27" "my-ssh.server.com" 22

# Leave this if you don't use signal-cli outside of this script,
# otherwise comment out, see readme
signal-cli -u $SIGNAL_USER receive > /dev/null 2>&1
