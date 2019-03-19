#!/bin/bash

if [ $# -ne 1 ]; then
  echo "No argument given, but properties file is required!"
  exit 1
else
  if [ ! -f "${1}" ]; then
    echo "File ${1} does not exist."
    exit 1
  fi
fi

PROPERTIES_FILE="${1}"

config_property() {
  local PROPERTY="${1}"
  local CONFIG="${2}"
  while IFS= read LINE; do
    KEY=`echo "${LINE}" | awk -F= ' { print $1 } '`
    if [ "${KEY}" = "${PROPERTY}" ]; then
      PROPERTY=`echo "${LINE}" | awk -F= ' { print $2 } '`
      break
    fi
  done < "${CONFIG}"
  if [ "${PROPERTY}" != "$1" ]; then
    echo "${PROPERTY}"
  else
    echo ""
  fi
}

trim() {
    [[ "$1" =~ [^[:space:]](.*[^[:space:]])? ]]
    printf "%s" "$BASH_REMATCH"
}

DEPLOYMENT_NAME=`config_property DEPLOYMENT_NAME "${PROPERTIES_FILE}"`
DEPLOYMENT_DIR=`config_property DEPLOYMENT_DIR "${PROPERTIES_FILE}"`
DEPLOYMENT_OBJECTS=`config_property DEPLOYMENT_OBJECTS "${PROPERTIES_FILE}"`
DEPLOYMENT_DESTINATION=`config_property DEPLOYMENT_DESTINATION "${PROPERTIES_FILE}"`
RELEASE_VERSION=`config_property RELEASE_VERSION "${PROPERTIES_FILE}"`
RELEASE_DATE=`date +"%Y-%m-%d"`
ERROR_STATUS=0
COMMAND=""
OLD_RELEASE_VERSION=`sed -En 's/(<Version>)([0-9].+)(<\/Version>)/\2/p' < "${DEPLOYMENT_DESTINATION}/meta/package.xml"`
OLD_RELEASE_VERSION=`trim "${OLD_RELEASE_VERSION}"`
OLD_RELEASE_DATE=`sed -En 's/(<ReleaseDate>)([0-9].+)(<\/ReleaseDate>)/\2/p' < "${DEPLOYMENT_DESTINATION}/meta/package.xml"`
OLD_RELEASE_DATE=`trim "${OLD_RELEASE_DATE}"`


echo "######################################################"
echo "DEPLOYMENT_NAME: ${DEPLOYMENT_NAME}"
echo "DEPLOYMENT_DIR: ${DEPLOYMENT_DIR}"
echo "DEPLOYMENT_OBJECTS: ${DEPLOYMENT_OBJECTS}"
echo "DEPLOYMENT_DESTINATION: ${DEPLOYMENT_DESTINATION}"
echo "OLD_RELEASE_VERSION: ${OLD_RELEASE_VERSION}"
echo "RELEASE_VERSION: ${RELEASE_VERSION}"
echo "OLD_RELEASE_DATE: ${OLD_RELEASE_DATE}"
echo "RELEASE_DATE: ${RELEASE_DATE}"
echo "######################################################"

echo "######################################################"
echo "Checking for errors."
if [ -z "${DEPLOYMENT_NAME}" ]; then
  echo "DEPLOYMENT_NAME is not set."
  ERROR_STATUS=1
fi
if [ ! -d "${DEPLOYMENT_DIR}" ]; then
  echo "Directory ${DEPLOYMENT_DIR} does not exist."
  ERROR_STATUS=1
fi
if [ -z "${DEPLOYMENT_OBJECTS}" ]; then
  echo "DEPLOYMENT_OBJECTS is not set."
  ERROR_STATUS=1
fi
if [ ! -d "${DEPLOYMENT_DESTINATION}" ]; then
  echo "Directory ${DEPLOYMENT_DESTINATION} does not exist."
  ERROR_STATUS=1
fi
if [ -z "${RELEASE_VERSION}" ]; then
  echo "RELEASE_VERSION is not set."
  ERROR_STATUS=1
fi
if [ -z "${RELEASE_DATE}" ]; then
  echo "RELEASE_DATE is not set."
  ERROR_STATUS=1
fi
COMMAND=`command -v 7z`
if [ -z "${COMMAND}" ]; then
  echo "7z is not installed."
  ERROR_STATUS=1
fi
COMMAND=`command -v sed`
if [ -z "${COMMAND}" ]; then
  echo "sed is not installed."
  ERROR_STATUS=1
fi
if [ $ERROR_STATUS -ne 0 ]; then
  echo "Found errors and cannot continue!"
  exit 1
else
  echo "No errors found."
fi
echo "######################################################"
echo "Changing directory to ${DEPLOYMENT_DIR}"
cd "${DEPLOYMENT_DIR}"
echo "Creativing 7z archive for ${DEPLOYMENT_OBJECTS}"
7z a "${DEPLOYMENT_NAME}" ${DEPLOYMENT_OBJECTS}
if [ ! $? -eq 0 ]; then
  echo "Previous command encountered an error!"
  exit 1
fi
echo "Moving ${DEPLOYMENT_NAME}.7z to ${DEPLOYMENT_DESTINATION}/data/"
mv -f "${DEPLOYMENT_NAME}.7z" "${DEPLOYMENT_DESTINATION}/data/"
if [ ! $? -eq 0 ]; then
  echo "Previous command encountered an error!"
  exit 1
fi
echo "Updating version from ${OLD_RELEASE_VERSION} to ${RELEASE_VERSION}"
sed -Ei 's/(<Version>)([0-9].+)(<\/Version>)/\1'"${RELEASE_VERSION}"'\3/' "${DEPLOYMENT_DESTINATION}/meta/package.xml"
if [ ! $? -eq 0 ]; then
  echo "Previous command encountered an error!"
  exit 1
fi
echo "Updating version from ${OLD_RELEASE_DATE} to ${RELEASE_DATE}"
sed -Ei 's/(<ReleaseDate>)([0-9].+)(<\/ReleaseDate>)/\1'"${RELEASE_DATE}"'\3/' "${DEPLOYMENT_DESTINATION}/meta/package.xml"
if [ ! $? -eq 0 ]; then
  echo "Previous command encountered an error!"
  exit 1
fi
exit 0
