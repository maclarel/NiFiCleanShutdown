## stop_nifi.sh

# Overview

Coordination of stopping all NiFi processors gracefully & faciliating a stop/restart of all NiFi instances on target servers.

# Requirements
- Python 2.7.5 Requests module as per nifi_shutdown.py further described below.
- macOS 10.13+ or RHEL/CentOS 7+ (will likely work on any OS with Bash 3.2 or higher)

# Usage
./stop_nifi.sh -n="<nifi_hosts>" -g=<root_guid> -p=<port> -l=</path/to/nifi> -a=<action> -u=<ssh_user> -i=<path_to_pem_file>

Handles nifi_shutdown.py and stops/restarts all NiFi instances on target servers at target path.

Arguments:

-	-n=*|--nifiHosts=*
	- This should be a quoted & space separate list of hosts (e.g. -n="host1.domain.com host2.domain.com").
-	-p=*|--port=*
	- This should be the UI/API port for the target NiFi instance (e.g. "8085").
-	-g=*|--processorGroup=*
	- This should be the root processor group in your environment (e.g. "fa0a5169-0163-1000-048a-febac436cf22").
-	-l=*|--nifiLoc=*
	- This should be the full path to the NiFi installation (e.g. "/opt/nifi/current").
-	-a=*|--action=*
	- The action to perform. Valid inputs are 'stop' or 'restart'.
-	-u=*|--sshUsr=*
	- (Optional) the user to SSH as. Defaults to "ec2-user".
-	-i=*|--pemPath=*
	- (Optional) private key to use for SSH to target servers. If not specified, you will be prompted for credentials.

# Limitations

- Primarily in nifi_shutdown.py, outlined below.


## nifi_shutdown.py

# Overview

This tooling exists to stop all NiFi processors in an environment in order to facilitate a clean shutdown without loss of data from processors storing values in memory. External tooling should be used to stop NiFi following the execution of this script.

If the thread count does not reach zero within 15 minutes this script will exit with a failure condition to ensure that other tooling calling it acknowledges that the shutdown did not complete.

# Requirements
Python 2.7.5 Requests module

# Usage
nifi_shutdown.py [-h] -nifi-host NIFI_HOST -nifi-port NIFI_PORT -processor-group PROCESSOR_GROUP_ID [-debug]

Stop all NiFi procesors within a processor group (and its child groups)

Arguments:
-  -h, --help            show this help message and exit
-  -nifi-host NIFI_HOST  the FQDN of the Nifi host
-  -nifi-port NIFI_PORT  the port NiFi runs on
-  -processor-group PROCESSOR_GROUP_ID the GUID of the ROOT processor group
-  -debug                display response JSON

You must pass this the ROOT processor group ID (e.g. the lowest level of cavas) as this will stop all processors in the flow, regardless of location.

# Troubleshooting

If the 'requests' module is not installed you will receive an error like "ImportError: No module named requests". This module, or other missing modules, can be installed with:

`pipenv install <module>`
or
`sudo easy_install <module>`

Note that this requires internet access, or for pip to be configured against a local repository. Configuring this is outside of the scoping of this tool and unfortunately non-trivial without also shipping a virtualenv.

# Limitations

- Currently this will only work targeting the root process group, as it expects the thread count to reach zero. Future revisions could include optionally ignoring the thread count if there is a desire to use this outside of the scope of shutting down an environment.
- This has no current support for secured environments. 