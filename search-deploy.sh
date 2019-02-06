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
export LOG_FILE="${PWD}/log_search_and_deploy_${DATE}.log"
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
  mkdir "$LIBRARIES" 2>&1 | tee -a "$LOG_FILE"
fi
PLUGINS=`config_property PLUGINS "$CONFIG"`
if [ "$PLUGINS" == "." ]; then
  PLUGINS="$WORKING_DIR"
else
  PLUGINS=`echo "$WORKING_DIR/$PLUGINS" | sed -E 's/\/\//\//g'`
  mkdir "$PLUGINS" 2>&1 | tee -a "$LOG_FILE"
fi
QML_IMPORT=`config_property QML_IMPORT "$CONFIG"`
if [ "$QML_IMPORT" == "." ]; then
  QML_IMPORT="$WORKING_DIR"
else
  QML_IMPORT=`echo "$WORKING_DIR/$QML_IMPORT" | sed -E 's/\/\//\//g'`
  mkdir "$QML_IMPORT" 2>&1 | tee -a "$LOG_FILE"
fi
EXECUTABLE=`config_property EXECUTABLE "$CONFIG"`
EXECUTABLE=`echo "$WORKING_DIR/$EXECUTABLE" | sed -E 's/\/\//\//g'`
NON_QT_LIBRARIES=`config_property NON_QT_LIBRARIES "$CONFIG"`
QT_SOURCE_LOCATION=`config_property QT_SOURCE_LOCATION "$CONFIG"`
if [ -n "$QT_SOURCE_LOCATION" ]; then
  QT_SOURCE_PLUGINS=`echo "$QT_SOURCE_LOCATION/plugins" | sed -E 's/\/\//\//g'`
  QT_SOURCE_QML_IMPORT=`echo "$QT_SOURCE_LOCATION/qml" | sed -E 's/\/\//\//g'`
  QT_SOURCE_LIBRARIES=`echo "$QT_SOURCE_LOCATION/lib" | sed -E 's/\/\//\//g'`
fi
QML_SOURCE=`config_property QML_SOURCE "$CONFIG"`

echo "########################################################" 2>&1 | tee -a "$LOG_FILE"
echo "CONFIG: $CONFIG" 2>&1 | tee -a "$LOG_FILE"
echo "DATE: $DATE" 2>&1 | tee -a "$LOG_FILE"
echo "LOG_FILE: $LOG_FILE" 2>&1 | tee -a "$LOG_FILE"
echo "WORKING_DIR: $WORKING_DIR" 2>&1 | tee -a "$LOG_FILE"
echo "LIBRARIES: $LIBRARIES" 2>&1 | tee -a "$LOG_FILE"
echo "PLUGINS: $PLUGINS" 2>&1 | tee -a "$LOG_FILE"
echo "QML_IMPORT: $QML_IMPORT" 2>&1 | tee -a "$LOG_FILE"
echo "EXECUTABLE: $EXECUTABLE" 2>&1 | tee -a "$LOG_FILE"
echo "NON_QT_LIBRARIES: $NON_QT_LIBRARIES" 2>&1 | tee -a "$LOG_FILE"
echo "QT_SOURCE_LOCATION: $QT_SOURCE_LOCATION" 2>&1 | tee -a "$LOG_FILE"
if [ -n "$QT_SOURCE_LOCATION" ]; then
  export LD_LIBRARY_PATH="$QT_SOURCE_LIBRARIES"
  echo "QT_SOURCE_PLUGINS: $QT_SOURCE_PLUGINS" 2>&1 | tee -a "$LOG_FILE"
  echo "QT_SOURCE_QML_IMPORT: $QT_SOURCE_QML_IMPORT" 2>&1 | tee -a "$LOG_FILE"
  echo "QT_SOURCE_LIBRARIES: $QT_SOURCE_LIBRARIES" 2>&1 | tee -a "$LOG_FILE"
fi
# Deploy library dependencies for the executable file
echo "########################################################" 2>&1 | tee -a "$LOG_FILE"
./deploy-libraries.sh "$LIBRARIES" "$EXECUTABLE" "$NON_QT_LIBRARIES" "$QT_SOURCE_LIBRARIES"
if [ $? -eq 1 ]; then
  exit 0
fi
echo "########################################################" 2>&1 | tee -a "$LOG_FILE"
# deploy_plugins can be replaced with manual plugins deployment by developer to ensure just specific plugins are deployed
deploy_plugins
if [ $? -eq 1 ]; then
  exit 0
fi
# Deleting unwanted plugins
if [ -f "$PLUGINS/sqldrivers/libqsqlmysql.so" ]; then
  echo "Removing $PLUGINS/sqldrivers/libqsqlmysql.so"
  rm -f "$PLUGINS/sqldrivers/libqsqlmysql.so" 2>&1 | tee -a "$LOG_FILE"
fi
if [ -f "$PLUGINS/sqldrivers/libqsqlpsql.so" ]; then
  echo "Removing $PLUGINS/sqldrivers/libqsqlpsql.so"
  rm -f "$PLUGINS/sqldrivers/libqsqlpsql.so" 2>&1 | tee -a "$LOG_FILE"
fi
if [ -f "$PLUGINS/imageformats/libqsvg.so" ]; then
  echo "Removing $PLUGINS/imageformats/libqsvg.so"
  rm -f "$PLUGINS/imageformats/libqsvg.so" 2>&1 | tee -a "$LOG_FILE"
fi
# Deploying qml imports
./deploy-qml.sh "$QML_IMPORT" "$QML_SOURCE" "$QT_SOURCE_LOCATION"
if [ $? -eq 1 ]; then
  exit 0
fi
cat << EOF |
`find "$PLUGINS"`
EOF
while read LINE; do
  if [ -f "$LINE" ]; then
    echo "LINE $LINE"
    ./deploy-libraries.sh "$LIBRARIES" "$LINE" "$NON_QT_LIBRARIES" "$QT_SOURCE_LIBRARIES"
    if [ $? -eq 1 ]; then
      exit 0
    fi
  fi
done
# Deploying qml plugins dependencies
cat << EOF |
`find "$QML_IMPORT" | sed -En '/lib.+/p'`
EOF
while read LINE; do
  if [ -f "$LINE" ]; then
    ./deploy-libraries.sh "$LIBRARIES" "$LINE" "$NON_QT_LIBRARIES" "$QT_SOURCE_LIBRARIES"
    if [ $? -eq 1 ]; then
      exit 0
    fi
  fi
done
# Searching for dependencies of dependencies added for plugins and qml imports
cat << EOF |
`find "$LIBRARIES"`
EOF
while read LINE; do
  if [ -f "$LINE" ]; then
    ./deploy-libraries.sh "$LIBRARIES" "$LINE" "$NON_QT_LIBRARIES" "$QT_SOURCE_LIBRARIES"
    if [ $? -eq 1 ]; then
      exit 0
    fi
  fi
done
# Making shell script for starting the application
if [ -f "${EXECUTABLE}.sh" ]; then
  echo "Removing ${EXECUTABLE}.sh"
  rm -rf "${EXECUTABLE}.sh"
fi
echo "Making clean ${EXECUTABLE}.sh"
echo "#!/bin/sh" >> "${EXECUTABLE}.sh"
echo "appname=\`basename \"\$0\" | sed 's/\.sh\$//'\`" >> "${EXECUTABLE}.sh"
echo "dirname=\`dirname \"\$0\"\`" >> "${EXECUTABLE}.sh"
echo "tmp=\"\${dirname#?}\"" >> "${EXECUTABLE}.sh"
echo "if [ \"\${dirname%\$tmp}\" != \"/\" ]; then" >> "${EXECUTABLE}.sh"
echo "dirname=\"\${PWD}/\${dirname}\"" >> "${EXECUTABLE}.sh"
echo "fi" >> "${EXECUTABLE}.sh"
echo "LD_LIBRARY_PATH=\"\${dirname}/lib\"" >> "${EXECUTABLE}.sh"
echo "export LD_LIBRARY_PATH" >> "${EXECUTABLE}.sh"
echo "\"\${dirname}/\${appname}\" \"\$@\"" >> "${EXECUTABLE}.sh"
chmod +x "${EXECUTABLE}.sh" 2>&1 | tee -a "$LOG_FILE"
exit 0
