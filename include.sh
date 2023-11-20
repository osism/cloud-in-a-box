
# Hint: Read the logfile with "less -r /var/log/install-cloud-in-a-box.log" for convenience
BOOTSTRAP_LOGFILE="/var/log/install-cloud-in-a-box.log"

if [[ -n "$BOOTSTRAP_LOGFILE" ]] ;then
   log_ident="$(basename $0|sed '~s,\.sh,,')"
   echo "Logging bootstrap process to $BOOTSTRAP_LOGFILE for $log_ident"
   exec 1> >(sed "~s,^,$log_ident | ," | sudo tee -a $BOOTSTRAP_LOGFILE)
   exec 2> >(sed "~s,^,$log_ident | ," | sudo tee -a $BOOTSTRAP_LOGFILE >&2)
fi

wait_for_container_healthy() {
    set +x
    local max_attempts="$1"
    local name="$2"
    local attempt_num=1
    echo "Checking if container '$name' is healthy"
    until [[ "$(/usr/bin/docker inspect -f '{{.State.Health.Status}}' $name 2>/dev/null)" == "healthy" ]]; do
        if (( attempt_num++ >= max_attempts )); then
            echo "ERROR: Max attempts reached waiting for container '$name' to be healthy"
            set -x
            exit 1
        else
            echo "$attempt_num/$max_attempts - Waiting for container '$name' to be healthy"
            sleep 5
        fi
    done
    return 0
}

wait_for_container_running() {
    set +x
    local max_attempts="$1"
    local name="$2"
    local attempt_num=1
    echo "Checking if container '$name' is running"
    until [[ "$(/usr/bin/docker inspect -f '{{.State.Status}}' $name 2>/dev/null)" == "running" ]]; do
        if (( attempt_num++ >= max_attempts )); then
            echo "ERROR: Max attempts reached waiting for container '$name' to be running"
            set -x
            exit 1
        else
            echo "$attempt_num/$max_attempts - Waiting for container '$name' to be running"
            sleep 5
        fi
    done
    return 0
}


wait_for_uplink_connection() {
   set +x
   local url_probe="$1"
   while true; do
       echo -e "\033[32m==> $(date) : Checking for available uplink : ${url_probe}\033[0m"
       if ( curl --max-time 5 "${url_probe}" >/dev/null );then
          echo
          echo -e "\033[32mSuccessfully checked ${url_probe}\033[0m"
          set -x
          return 0
       else
          echo -e "\033[31mWaiting for a successful fetch of ${url_probe} to ensure that a suitable uplink is available\033[0m"
          echo "(Check that the network card is properly plugged, dhcp available, and the network provides a internet uplink)"
       fi
       sleep 2
   done
}

get_ethernet_interface_of_default_gateway() {
   ip --json -4 route ls | \
      jq 'sort_by(.dev)' | \
      jq -r 'first(.[] | select(.dst == "default" and .protocol == "dhcp")) | .dev'
}

get_v4_ip_of_default_gateway() {
   ip --json -4 route ls | \
      jq 'sort_by(.dev)' | \
      jq -r 'first(.[] | select(.dst == "default" and .protocol == "dhcp")) | .prefsrc'
}


get_default_gateway_settings() {
   ip --json route ls | \
      jq 'sort_by(.dev)' | \
      jq -r 'first(.[] | select(.dst == "default" and .protocol == "dhcp")) | "device " + .dev + "with ip address " + .prefsrc + " with gateway " + .gateway'
}

add_status(){
   local type="$1"
   local text="$2"

   if [ "$type" = "warn" ];then
     text="\e[5;43;1mWARNING: $text\e[0m"
   elif [ "$type" = "info" ];then
     text="\e[5;42;1mINFORMATION: $text\e[0m"
   else
     text="\e[5;41;1mALERT: $text\e[0m"
   fi

   if [[ "$type" = "info" ]] && [[ -n "$BOOTSTRAP_LOGFILE" ]];then
       text="$text\n\nReview the progress in $BOOTSTRAP_LOGFILE"
   elif [[ -n "$BOOTSTRAP_LOGFILE" ]];then
       text="$text\n\nReview $BOOTSTRAP_LOGFILE to analyze what went wrong"
   fi

   echo -e "$text" | sudo tee /etc/issue.net
   echo -e "$text" | sudo tee /etc/issue
}

