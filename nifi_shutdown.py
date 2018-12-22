import argparse
import json
import logging
import requests
import time

'''
usage: nifi_shutdown.py [-h] -nifi-host NIFI_HOST -nifi-port NIFI_PORT -processor-group
                              PROCESSOR_ID [-debug]

Stop all NiFi procesors within a processor group (and its child groups)

optional arguments:
  -h, --help            show this help message and exit
  -nifi-host NIFI_HOST  the FQDN of the Nifi host
  -nifi-port NIFI_PORT  the port NiFi runs on
  -processor-group PROCESSOR_GROUP_ID
                        the GUID of the ROOT processor group
  -debug                display response JSON

'''

nifi_host=""
nifi_port=""
processor_group_id=""

def processor_put_url():
    # Construct URL to PUT to
    url = "http://{nifi_host}:{nifi_port}/nifi-api/flow/process-groups/{processor_group_id}".format(
        nifi_host=nifi_host,
        nifi_port=nifi_port,
        processor_group_id=processor_group_id
    )
    return url

def flow_url():
    # Construct URL to retrieve thread count from
    url = "http://{nifi_host}:{nifi_port}/nifi-api/flow/status".format(
        nifi_host=nifi_host,
        nifi_port=nifi_port,
    )
    return url

def set_processor_group_state(state):
    state = state.upper()
    logging.info("setting processor group {pid}'s state to {state}...".format(pid=processor_group_id, state=state))

    # Specify URL for use within function and create payload
    url = processor_put_url()
    payload = {
        'id':processor_group_id,
        'state':state
    }
    headers = {'Content-Type': 'application/json'}
    response = requests.put(url, headers=headers, data=json.dumps(payload))
    logging.info("obtained an HTTP {status} response".format(status=response.status_code))

    # Handle errors (e.g. 400/405/500/etc...)
    if response.status_code > 399:
        logging.error("request failed with status code {code} {reason}".format(code=response.status_code, reason=response.reason))
        logging.error("response text:\n" + response.text)
    logging.debug("new processor status:")

def get_flow_status():
    return json.loads(requests.get(flow_url()).text)


def wait_for_shutdown():
    # Get current status and initialize variables
    thread_count = get_flow_status()
    logging.debug("current flow status:\n{}".format(json.dumps(thread_count, indent=2)))
    count = thread_count['controllerStatus']['activeThreadCount']
    wait_timer = 0

    # Wait until thread count reaches zero, or fail after 15 minutes.
    while (count > 0):
        print "Waiting for Active Thread Count to reach 0. Active Thread Count is:", count
        thread_count = get_flow_status()
        count = thread_count['controllerStatus']['activeThreadCount']
        time.sleep(5)
        wait_timer = wait_timer + 10
        if wait_timer > 900:
                print "Exiting with failure as count has not reached zero after 15 minutes."
                exit(1)

if __name__=='__main__':
    parser = argparse.ArgumentParser(description='Stop process group and wait for all processors to stop.')
    parser.add_argument('-nifi-host', dest='nifi_host', type=str, help='the FQDN of the NiFi host', required=True)
    parser.add_argument('-nifi-port', dest='nifi_port', type=str, help='the port NiFi runs on', required=True)
    parser.add_argument('-processor-group', dest='processor_group_id', type=str, help='the GUID of the NiFi processor group', required=True)
    parser.add_argument('-debug', dest='debug', action='store_true', help='display response JSON', required=False)
    args = parser.parse_args()
    if args.debug:
        logging.basicConfig(format='%(asctime)s %(levelname)s: %(message)s', level=logging.DEBUG)
    else:
        logging.basicConfig(format='%(asctime)s %(levelname)s: %(message)s', level=logging.INFO)

    nifi_host = args.nifi_host
    nifi_port = args.nifi_port
    processor_group_id = args.processor_group_id

    set_processor_group_state('stopped')
    wait_for_shutdown()
