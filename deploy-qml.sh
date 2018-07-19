#!/bin/bash
. util.sh
if [ ! "$#" -eq 3 ]; then
  echo "This script requires 3 arguments($# where provided)."
  echo "1. QML destination directory."
  echo "2. QML root directory(where the qml source code is)."
  echo "3. Qt installation, for targeted platform."
  echo "Example: ./deploy-qml.sh /destination/directory /qml/source/code /qt/installation/location"
  exit 1
fi
if [ -z "$DATE" ]; then
  DATE=`date +"%Y-%m-%d"_%H:%M:%S`
fi
if [ -z "$LOG_FILE" ]; then
  LOG_FILE="$PWD/log_import_qml_$DATE.log"
  touch "$LOG_FILE"
fi
echo "Deploying QML imports." | tee -a "$LOG_FILE"
WORKING_DIR="$1"
QML_ROOT_PATH="$2"
QML_IMPORT_PATH=`echo "$3/qml" | sed -E 's/\/\//\//g'`
QML_IMPORT_SCANNER=`echo "$3/bin/qmlimportscanner" | sed -E 's/\/\//\//g'`
QML_IMPORT_SCANNER=`command -v "$QML_IMPORT_SCANNER"`
if [ ! -d "$WORKING_DIR" ]; then
  echo "$WORKING_DIR not found, exiting!"
  exit 1
fi
#Directory containing QML source code used in application
if [ ! -d "$QML_ROOT_PATH" ]; then
  echo "$QML_ROOT_PATH not found, exiting!" | tee -a "$LOG_FILE"
  exit 1
fi
#Directory containing QML dependencies to be deployed
if [ ! -d "$QML_IMPORT_PATH" ]; then
  echo "$QML_IMPORT_PATH not found, exiting!" | tee -a "$LOG_FILE"
  exit 1
fi
if [ -z "$QML_IMPORT_SCANNER" ]; then
  echo "qmlimportscanner not found, exiting!" | tee -a "$LOG_FILE"
  exit 1
fi
cat <<EOF |
`"$QML_IMPORT_SCANNER" \
-rootPath "$QML_ROOT_PATH" \
-importPath "$QML_IMPORT_PATH" \
| tee -a "$LOG_FILE" \
| jq '.[] | {qml: ("@"+.classname+"@"+.name+"@"+.path+"@"+.plugin+"@"+.type)}' \
| sed -En 's/(\ \ \"qml\":\ \")(@.+)(\")/\2/p'`
EOF

while read LINE; do
  IMPORT_CLASSNAME=`echo "$LINE" | awk -F@ ' { print $2 } '`
  IMPORT_NAME=`echo "$LINE" | awk -F@ ' { print $3 } '`
  IMPORT_PLUGIN_PATH=`echo "$LINE" | awk -F@ ' { print $4 } '`
  IMPORT_PLUGIN=`echo "$LINE" | awk -F@ ' { print $5 }'`
  IMPORT_TYPE=`echo "$LINE" | awk -F@ ' { print $6 }'`
  if [ "$IMPORT_TYPE" == "directory" ]; then
    if [ $IMPORT_NAME == "qml" ]; then
      IMPORT_PLUGIN=`echo "$IMPORT_PLUGIN_PATH" | sed -En 's/\/qml//2gp'`
      IMPORT_PLUGIN_PATH=`echo "$IMPORT_PLUGIN_PATH" | sed -En 's/(\/[A-Za-z][A-Za-z]*\.qml\/qml)//p'`
    else
      IMPORT_PLUGIN=`echo "$IMPORT_PLUGIN_PATH"`
      IMPORT_PLUGIN_PATH=`echo "$IMPORT_PLUGIN_PATH" | sed -En 's/(\/[A-Za-z][A-Za-z]*\.qml)//p'`
    fi
  fi
  IMPORT_DEST_DIR="$WORKING_DIR"`echo "$IMPORT_PLUGIN_PATH" | sed -En 's/.*\/qml//p'`
  echo "*********Copying $IMPORT_NAME**************" |  tee -a "$LOG_FILE"
  echo "$LINE" |  tee -a "$LOG_FILE"
  echo "IMPORT_CLASSNAME:$IMPORT_CLASSNAME" |  tee -a "$LOG_FILE"
  echo "IMPORT_NAME:$IMPORT_NAME" |  tee -a "$LOG_FILE"
  echo "IMPORT_PLUGIN_PATH:$IMPORT_PLUGIN_PATH" |  tee -a "$LOG_FILE"
  echo "IMPORT_PLUGIN:$IMPORT_PLUGIN" |  tee -a "$LOG_FILE"
  echo "IMPORT_TYPE:$IMPORT_TYPE" |  tee -a "$LOG_FILE"
  echo "IMPORT_DEST_DIR:$IMPORT_DEST_DIR" |  tee -a "$LOG_FILE"
  if [ ! -z "$IMPORT_PLUGIN_PATH" ]; then
    mkdir -p "$IMPORT_DEST_DIR" 2>> "$LOG_FILE"
    echo "Copying the following:" | tee -a "$LOG_FILE"
    ls -l "$IMPORT_PLUGIN_PATH"/* | tee -a "$LOG_FILE"
    cp -R "$IMPORT_PLUGIN_PATH"/* "$IMPORT_DEST_DIR/" 2>> "$LOG_FILE"
  fi
done
