#!/bin/bash
. util.sh
if [ "$#" -lt 3 ]; then
  echo "This script requires at least 3 arguments($# where provided)."
  echo "1. Plugins destination directory."
  echo "2. Qt source plugins directory."
  echo "3. Plugins list as arguments "
  echo "The plugins should be:"
  echo "- the name of the directory"
  echo "or"
  echo "- the path to the plugin."
  echo "Relative to the plugins directory path."
  echo "Example: ./deploy-plugins.sh /destination/directory /home/user/Qt/path/to/plugins platforms/libqxcb.so sqldrivers/libqsqlite.so xcbglintegrations"
  exit 1
fi
if [ -z "$DATE" ]; then
  DATE=`date +"%Y-%m-%d"_%H:%M:%S`
fi
if [ -z "$LOG_FILE" ]; then
  LOG_FILE="$PWD/log_deploy_plugins_$DATE.log"
  touch "$LOG_FILE"
fi
echo "Deploying plugins." | tee -a "$LOG_FILE"
for var in "$@"; do
  if [ "$var" == "$1" ]; then
    PLUGINS_DIR="$1"
    if [ ! -d "$PLUGINS_DIR" ]; then
      echo "$PLUGINS_DIR is not a directory, exiting!" | tee -a "$LOG_FILE"
      exit 1
    fi
  elif [ "$var" == "$2" ]; then
    QT_PLUGINS_DIR="$2"
    if [ ! -d "$QT_PLUGINS_DIR" ]; then
      echo "$QT_PLUGINS_DIR is not a directory, exiting!" | tee -a "$LOG_FILE"
      exit 1
    fi
  else
    PLUGIN=`echo "$QT_PLUGINS_DIR/$var" | sed -E 's/\/\//\//g'`
    DESTINATION_PATH=`echo "$PLUGINS_DIR/$var" | sed -E 's/\/\//\//g' | sed -E 's/lib[a-zA-Z].*.so//'`
    echo "Making directory $DESTINATION_PATH" | tee -a "$LOG_FILE"
    mkdir -p "$DESTINATION_PATH" 2>> "$LOG_FILE"
    echo "Copying plugin $PLUGIN at $DESTINATION_PATH" | tee -a "$LOG_FILE"
    if [ -d "$PLUGIN" ]; then
      cp -R "$PLUGIN" "$PLUGINS_DIR" 2>> "$LOG_FILE"
    elif [ -f "$PLUGIN" ]; then
      cp "$PLUGIN" "$DESTINATION_PATH" 2>> "$LOG_FILE"
    else
      echo "$PLUGIN does not exist" | tee -a "$LOG_FILE"
      exit 1
    fi
  fi
done
echo "Variables used:" | tee -a "$LOG_FILE"
echo "LOG_FILE: $LOG_FILE"
echo "PLUGINS_DIR: $PLUGINS_DIR" | tee -a "$LOG_FILE"
echo "QT_PLUGINS_DIR: $QT_PLUGINS_DIR" | tee -a "$LOG_FILE"
exit 0
