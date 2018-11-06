#!/bin/bash
# Based on :
#   https://cowboyprogrammer.org/2016/09/reboot_machine_on_wrong_password/

MAX_FAIL_COUNT=5
COUNTFILE="/tmp/failed_auth_count"

if [ ! -f "$COUNTFILE" ]; then
  echo "0" > "$COUNTFILE"
  chmod 777 "$COUNTFILE"
fi

if   [[ "$PAM_TYPE" == "auth" ]]; then    # Authentication phase
  # Read and increment counter
  COUNT=$(cat "$COUNTFILE")
  COUNT=$[$COUNT + 1]

  # Write counter
  echo "$COUNT" > "$COUNTFILE"

  if (( "$COUNT" >= "$MAX_FAIL_COUNT" )); then
    # Schedule shutdown in one minute
    shutdown +1
  fi
elif [[ "$PAM_TYPE" == "account" ]]; then # Account phase
  # Reaching this phase means authentication phase is completed

  # Reset counter
  echo "0" > "$COUNTFILE"

  # Cancel shutdown
  shutdown -c
fi

exit 0
