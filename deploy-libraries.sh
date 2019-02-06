#!/bin/bash
. util.sh
if [ "$#" -lt 3 ]; then
  echo "This script requires 3 arguments($# where provided)."
  echo "1. Libraries destination directory."
  echo "2. Executable / Library which requires the libraries.(target of ldd)"
  echo "3. Deploy non Qt libraries.(Y/N)"
  echo "4. Qt libraries location, Qt libraries will deployed from here.(optional)"
  echo "Example: ./deploy-libraries.sh /destination/directory /path/to/executable false"
  exit 1
fi
SATUS="0"
if [ -z "$DATE" ]; then
  DATE=`date +"%Y-%m-%d"_%H:%M:%S`
fi
if [ -z "$LOG_FILE" ]; then
  LOG_FILE="${PWD}/log_deploy_libraries_${DATE}.log"
  touch "$LOG_FILE"
fi
echo "Deploying libraries." 2>&1 | tee -a "$LOG_FILE"
LIBRARIES="$1"
EXECUTABLE="$2"
NON_QT_LIBRARIES=`echo "$3" | sed -nE 's/y|yes|true/true/I p'`
QT_SOURCE_LIBRARIES="$4"
if [ ! -d "$LIBRARIES" ]; then
  echo "$LIBRARIES not found!" 2>&1 | tee -a "$LOG_FILE"
  STATUS="1"
fi
if [ ! -f "$EXECUTABLE" ]; then
  echo "$EXECUTABLE not found!" 2>&1 | tee -a "$LOG_FILE"
  STATUS="1"
fi
if [ -z "$NON_QT_LIBRARIES" ]; then
  NON_QT_LIBRARIES=`echo "$3" | sed -nE 's/n|no|false/false/I p'`
fi
if [ -z "$NON_QT_LIBRARIES" ]; then
  echo "Deploy non Qt libraries is not a valid value.(Y/N)" 2>&1 | tee -a "$LOG_FILE"
  echo "$3 was provided" 2>&1 | tee -a "$LOG_FILE"
  STATUS="1"
fi
LDD=`command -v ldd`
if [ -z "$LDD" ]; then
  echo "ldd not found!" 2>&1 | tee -a "$LOG_FILE"
  STATUS="1"
fi
if [ "$STATUS" == "1" ]; then
  echo "Check the log for issues, solve them and try again!"
  exit 1
fi
echo "Libraries destination: $LIBRARIES" 2>&1 | tee -a "$LOG_FILE"
cat << EOF |
`ldd $EXECUTABLE`
EOF

while read LINE; do
  DEPENDENCY="$LINE"
  # Check if we only deploy Qt libraries
  if [ "$NON_QT_LIBRARIES" == "false" ]; then
    DEPENDENCY=`echo "$LINE" | sed -En '/Qt/p'`
  fi
  if [ -n "$DEPENDENCY" ]; then
    DEPENDENCY_NAME=`echo "$DEPENDENCY" | sed -En 's/\ =>\ .*//p'`
    DEPENDENCY_NAME=`trim "$DEPENDENCY_NAME"`
    # If we find the library in the custom qt installation we continue with that
    if [ -f "${QT_SOURCE_LIBRARIES}/${DEPENDENCY_NAME}" ]; then
      DEPENDENCY="${QT_SOURCE_LIBRARIES}/${DEPENDENCY_NAME}"
      echo "$DEPENDENCY found in Qt installation, deploying from here." 2>&1 | tee -a "$LOG_FILE"
      # Otherwise we continue with the one from the system
    else
      DEPENDENCY=`echo "$DEPENDENCY" | sed -En 's/.*\ =>\ //p' | sed -En 's/\ .*//p'`
      if [ -n "$DEPENDENCY" ]; then
        echo "$DEPENDENCY found in system, deploying from here." 2>&1 | tee -a "$LOG_FILE"
      else
        echo "$LINE not found anywhere." 2>&1 | tee -a "$LOG_FILE"
      fi
    fi
    # We ensure again that a dependency was found in the system
    if [ -n "$DEPENDENCY" ]; then
      # We make sure to not override any existing library and let developer know there is an existing library deployed
      if [ ! -f "${LIBRARIES}/${DEPENDENCY_NAME}" ]; then
        echo "Copying $DEPENDENCY" 2>&1 | tee -a "$LOG_FILE"
        echo "To $LIBRARIES" 2>&1 | tee -a "$LOG_FILE"
        cp "$DEPENDENCY" "$LIBRARIES" 2>&1 | tee -a "$LOG_FILE"
        if [ "$?" -ne 0 ]; then
          echo "Exit code of cp is $?, check $LOG_FILE for error message!" 2>&1 | tee -a "$LOG_FILE"
        fi
      else
        echo "File $LIBRARIES/$DEPENDENCY_NAME exists, skipping!" 2>&1 | tee -a "$LOG_FILE"
        echo "If you want to delete it, copy and paste the following command in terminal: rm $LIBRARIES/$DEPENDENCY_NAME" 2>&1 | tee -a "$LOG_FILE"
      fi
    else
      echo "Warning, $LINE not deployed." 2>&1 | tee -a "$LOG_FILE"
    fi
  fi
done

echo "Variables used:" 2>&1 | tee -a "$LOG_FILE"
echo "LOG_FILE: $LOG_FILE"
echo "EXECUTABLE: $EXECUTABLE" 2>&1 | tee -a "$LOG_FILE"
echo "LIBRARIES: $LIBRARIES" 2>&1 | tee -a "$LOG_FILE"
echo "NON_QT_LIBRARIES: $NON_QT_LIBRARIES" 2>&1 | tee -a "$LOG_FILE"
echo "LDD: $LDD" 2>&1 | tee -a "$LOG_FILE"
exit 0
