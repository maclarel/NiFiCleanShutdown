#!/bin/bash


# garbage
# Exit on error
set -e

# Space separated list of NiFi hosts
NIFI_HOSTS=""
# Port for NiFi API calls (e.g. 8085)
NIFI_PORT=""
# Processor group to stop (should be the root processor group)
PROCESSOR_GROUP=""
# NiFi installation path on all nodes (e.g. /opt/nifi-1.4.0)
NIFI_LOC=""
# Action to perform on NiFi (e.g. stop/restart)
NIFI_ACTION=""
# User to transfer the file as (default "ec2-user" if not specified). This user must have 'sudo' privileges on all machines.
SSH_USR=""
# Path to .pem file for SSH access as the user noted above.
PEM_PATH=""

for i in "$@"; do
	case $i in
	    -n=*|--nifiHosts=*)
	    NIFI_HOSTS="${i#*=}"
	    shift
	    ;;
	    -p=*|--port=*)
	    NIFI_PORT="${i#*=}"
	    shift
	    ;;
	    -g=*|--processorGroup=*)
	    PROCESSOR_GROUP="${i#*=}"
	    shift
	    ;;
	    -l=*|--nifiLoc=*)
		NIFI_LOC="${i#*=}"
		shift
		;;
		-a=*|--action=*)
		NIFI_ACTION="${i#*=}"
		shift
		;;
		-u=*|--sshUsr=*)
		SSH_USR="${i#*=}"
		shift
		;;
		-i=*|--pemPath=*)
		PEM_PATH="${i#*=}"
		shift
		;;
	    *)
	          # unknown option
	    ;;
	esac
done

# Validate inputs
if [ -z "$NIFI_HOSTS" ]; then
	echo "NIFI_HOSTS (-n=*|--nifiHosts=*) must be populated with a valid value! This should be a quoted & space separate list of hosts (e.g. -n=\"host1.domain.com host2.domain.com\")."
	exit 1
fi

if [ -z $NIFI_PORT ]; then
	echo "NIFI_PORT (-p=*|--port=*) must be populated! This should be the UI/API port for the target NiFi instance (e.g. \"8085\")."
	exit 1
fi

if [ -z $PROCESSOR_GROUP ]; then
	echo "PROCESSOR_GROUP (-g=*|--processorGroup=*) must be populated! This should be the root processor group in your environment (e.g. \"fa0a5169-0163-1000-048a-febac436cf22\")."
	exit 1
fi

if [ -z $NIFI_LOC ]; then
	echo "NIFI_LOC (-l=*|--nifiLoc=*) must be populated! This should be the full path to the NiFi installation (e.g. \"/opt/nifi/current\")."
	exit 1
fi

if [ -z "$NIFI_ACTION" ] || [[ "$NIFI_ACTION" != "stop" && "$NIFI_ACTION" != "restart" ]]; then
	echo "NIFI_ACTION (-a=*|--action=*) must be populated with a valid value! Valid inputs are 'stop' or 'restart'."
	exit 1
fi

if [ -z $SSH_USR ]; then
	echo "SSH_USR is not populated, defaulting to \"interset\""
	SSH_USR="interset"
fi

if [ -z $PEM_PATH ]; then
	echo "PEM_PATH is not specified. You will be prompted for passwords!"
	SSH_CMD="ssh"
else
	SSH_CMD="ssh -i $PEM_PATH"
fi

# Identify first host in the list for API calls
NIFI1=$(echo $NIFI_HOSTS | awk '{print $1}')

function scriptHome() {
	# Set working directory so files don't fly all over the place
	SCRIPT_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"
}

function cleanShutdown() {
	# Perform a clean shutdown of all NiFi processors with nifi_shutdown.py
	if [ ! -f $SCRIPT_HOME/nifi_shutdown.py ]; then
			echo "nifi_shutdown.py not found. Exiting."
			exit 1
	fi

	python $SCRIPT_HOME/nifi_shutdown.py -nifi-host $NIFI1 -nifi-port $NIFI_PORT -processor-group $PROCESSOR_GROUP
}

function stopNiFi() {
	# SSH to each specified NiFi node and stop NiFi
	for h in $NIFI_HOSTS; do
			NIFI_CMD="$SSH_CMD $SSH_USR@${h} sudo $NIFI_LOC/bin/nifi.sh $NIFI_ACTION"
			eval $NIFI_CMD
	done
}

function main() {
	scriptHome
	cleanShutdown
	stopNiFi
}

main