#!/bin/bash

LOG_FILE="/tmp/test.log"
MAX_SIZE=1073741824  # 1 GB in bytes
JENKINS_JOB_URL="http://localhost:8080/job/log-file-upload-job/build"
JENKINS_USER="Shubham_Sarkar"                     # your Jenkins username
JENKINS_API_TOKEN="112106bf4353cab218ae48e3c5167a2360" # from Jenkins > Configure

if [ -f "$LOG_FILE" ]; then
  FILE_SIZE=$(stat -c %s "$LOG_FILE")
  if [ "$FILE_SIZE" -ge "$MAX_SIZE" ]; then
    echo " Log file exceeds 1 GB. Triggering Jenkins job..."
    curl -X POST "$JENKINS_JOB_URL" --user "$JENKINS_USER:$JENKINS_API_TOKEN"
  else
    echo " Log file size is below 1 GB. No action taken."
  fi
else
  echo " Log file does not exist: $LOG_FILE"
fi
