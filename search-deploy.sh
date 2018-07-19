#!/bin/bash
. util.sh
if [ "$#" -eq 0 ]; then
  if [ -f "deploy.properties" ]; then
    CONFIG="deploy.properties"
  else
    echo "Configuration file missing!"
    exit 1
  fi
else
  CONFIG="$1"
fi
export DATE=`date +"%Y-%m-%d"_%H:%M:%S`
# Comment the following line if you want log to be made for each script instead of one big log file
export LOG_FILE="$PWD/log_search_and_deploy_$DATE.log"
if [ ! -f "$CONFIG" ]; then
  echo "Configuration file is not valid, please provide a valid one!"
  exit 1
fi
WORKING_DIR=`config_property WORKING_DIR "$CONFIG"`
LIBRARIES=`config_property LIBRARIES "$CONFIG"`
if [ "$LIBRARIES" == "." ]; then
  LIBRARIES="$WORKING_DIR"
else
  LIBRARIES=`echo "$WORKING_DIR/$LIBRARIES" | sed -E 's/\/\//\//g'`
  mkdir "$LIBRARIES"
fi
PLUGINS=`config_property PLUGINS "$CONFIG"`
if [ "$PLUGINS" == "." ]; then
  PLUGINS="$WORKING_DIR"
else
  PLUGINS=`echo "$WORKING_DIR/$PLUGINS" | sed -E 's/\/\//\//g'`
  mkdir "$PLUGINS"
fi
QML_IMPORT=`config_property QML_IMPORT "$CONFIG"`
if [ "$QML_IMPORT" == "." ]; then
  QML_IMPORT="$WORKING_DIR"
else
  QML_IMPORT=`echo "$WORKING_DIR/$QML_IMPORT" | sed -E 's/\/\//\//g'`
  mkdir "$QML_IMPORT"
fi
EXECUTABLE=`config_property EXECUTABLE "$CONFIG"`
EXECUTABLE=`echo "$WORKING_DIR/$EXECUTABLE" | sed -E 's/\/\//\//g'`
NON_QT_LIBRARIES=`config_property NON_QT_LIBRARIES "$CONFIG"`
QT_SOURCE_LOCATION=`config_property QT_SOURCE_LOCATION "$CONFIG"`
if [ ! -z "$QT_SOURCE_LOCATION" ]; then
  QT_SOURCE_PLUGINS=`echo "$QT_SOURCE_LOCATION/plugins" | sed -E 's/\/\//\//g'`
  QT_SOURCE_QML_IMPORT=`echo "$QT_SOURCE_LOCATION/qml" | sed -E 's/\/\//\//g'`
  QT_SOURCE_LIBRARIES=`echo "$QT_SOURCE_LOCATION/lib" | sed -E 's/\/\//\//g'`
fi
QML_SOURCE=`config_property QML_SOURCE "$CONFIG"`
./deploy-libraries.sh "$LIBRARIES" "$EXECUTABLE" "$NON_QT_LIBRARIES" "$QT_SOURCE_LIBRARIES"
# deploy_plugins can be replaced with manual plugins deployment by developer to ensure just specific plugins are deployed
deploy_plugins
./deploy-qml.sh "$QML_IMPORT" "$QML_SOURCE" "$QT_SOURCE_LOCATION"
cat << EOF |
`find "$LIBRARIES"`
EOF
while read LINE; do
  if [ -f "$LINE" ]; then
    ./deploy-libraries.sh "$LIBRARIES" "$LINE" "$NON_QT_LIBRARIES" "$QT_SOURCE_LIBRARIES"
  fi
done
cat << EOF |
`find "$PLUGINS"`
EOF
while read LINE; do
  if [ -f "$LINE" ]; then
    ./deploy-libraries.sh "$LIBRARIES" "$LINE" "$NON_QT_LIBRARIES" "$QT_SOURCE_LIBRARIES"
  fi
done
