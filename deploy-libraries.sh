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
if [ -z "$DATE" ]; then
  DATE=`date +"%Y-%m-%d"_%H:%M:%S`
fi
if [ -z "$LOG_FILE" ]; then
  LOG_FILE="$PWD/log_deploy_libraries_$DATE.log"
  touch "$LOG_FILE"
fi
echo "Deploying libraries." | tee -a "$LOG_FILE"
LIBRARIES="$1"
EXECUTABLE="$2"
NON_QT_LIBRARIES=`echo "$3" | sed -nE 's/y|yes|true/true/I p'`
QT_SOURCE_LIBRARIES="$4"
if [ ! -d "$LIBRARIES" ]; then
  echo "$LIBRARIES not found, exiting!" | tee -a "$LOG_FILE"
  exit 1
fi
if [ ! -f "$EXECUTABLE" ]; then
  echo "$EXECUTABLE not found, exiting!" | tee -a "$LOG_FILE"
  exit 1
fi
if [ -z "$NON_QT_LIBRARIES" ]; then
  NON_QT_LIBRARIES=`echo "$3" | sed -nE 's/n|no|false/false/I p'`
fi
if [ -z "$NON_QT_LIBRARIES" ]; then
  echo "Deploy non Qt libraries is not a valid value.(Y/N)" | tee -a "$LOG_FILE"
  echo "$3 was provided" | tee -a "$LOG_FILE"
  exit 1
fi
LDD=`command -v ldd`
if [ -z "$LDD" ]; then
  echo "ldd not found, exiting script!" | tee -a "$LOG_FILE"
  exit 1
fi
echo "Libraries destination: $LIBRARIES" | tee -a "$LOG_FILE"
cat << EOF |
`ldd $EXECUTABLE`
EOF

while read LINE; do
  DEPENDENCY="$LINE"
  if [ "$NON_QT_LIBRARIES" == "false" ]; then
    DEPENDENCY=`echo "$LINE" | sed -En '/Qt/p'`
  fi
  if [ ! -z "$DEPENDENCY" ]; then
    DEPENDENCY=`echo "$DEPENDENCY" | sed -E 's/[a-zA-Z].*\ =>\ //' | sed -En 's/\ \(.*\)//p'`
    echo "DEPENDENCY: $DEPENDENCY" | tee -a "$LOG_FILE"
    DEPENDENCY_NAME=`echo "$DEPENDENCY" | sed -En 's@(\/.*)(lib.*\.so.[0-9]*)(.*)@\2@p'`
    echo "DEPENDENCY_NAME: $DEPENDENCY_NAME" | tee -a "$LOG_FILE"
    if [ -f "$LIBRARIES/$DEPENDENCY_NAME" ]; then
      echo "File $LIBRARIES/$DEPENDENCY_NAME exists, skipping!" | tee -a "$LOG_FILE"
      echo "If you want to delete it, copy and paste the following command in terminal: rm $LIBRARIES/$DEPENDENCY_NAME" | tee -a "$LOG_FILE"
      continue
    fi
    IS_QT_LIB=`echo "$DEPENDENCY" | sed -En '/Qt/I p'`
    if [ ! -z "$IS_QT_LIB" ]; then
      echo "Is Qt library." | tee -a "$LOG_FILE"
    fi
    if [ ! -z "$QT_SOURCE_LIBRARIES" -a ! -z "$IS_QT_LIB" ]; then
      echo "QT_SOURCE_LIBRARIES: $QT_SOURCE_LIBRARIES" | tee -a "$LOG_FILE"
      DEPENDENCY=`echo "$DEPENDENCY" | sed -En 's@(\/.*)(lib.*\.so.[0-9]*)(.*)@'"$QT_SOURCE_LIBRARIES/"'\2@p'`
      echo "New DEPENDENCY: $DEPENDENCY" | tee -a "$LOG_FILE"
    fi
    echo "Copying $DEPENDENCY" | tee -a "$LOG_FILE"
    echo "To $LIBRARIES" | tee -a "$LOG_FILE"
    cp "$DEPENDENCY" "$LIBRARIES" 2>&1 | tee -a "$LOG_FILE"
    if [ "$?" != "0" ]; then
      echo "Exit code of cp is $?, check $LOG_FILE for error message!" | tee -a "$LOG_FILE"
    fi
  fi
done

echo "Variables used:" | tee -a "$LOG_FILE"
echo "LOG_FILE: $LOG_FILE"
echo "EXECUTABLE: $EXECUTABLE" | tee -a "$LOG_FILE"
echo "LIBRARIES: $LIBRARIES" | tee -a "$LOG_FILE"
echo "NON_QT_LIBRARIES: $NON_QT_LIBRARIES" | tee -a "$LOG_FILE"
echo "LDD: $LDD" | tee -a "$LOG_FILE"
