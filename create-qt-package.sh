#!/bin/bash
. util.sh

RELEASE_DATE=`date +"%Y-%m-%d"`
ERROR_STATUS=0
INSTALLER_NAME="Cumulus-@installertype@-installer-x64"
INSTALLER_TOOL_DIR="/home/adi/Programe/Qt/Tools/QtInstallerFramework/3.0/bin"
REPO_TOOL_DIR="/home/adi/Programe/Qt/Tools/QtInstallerFramework/3.0/bin"
PACKAGES_DIR="/media/Workspace/Cumulus-package"
REPOSITORY_DIR="/media/Workspace/cumulus-repo"
CREATE_OFFLINE_PACKAGE="true"
CREATE_ONLINE_PACKAGE="true"
CREATE_NEW_REPOSITORY="false"
UPDATE_REPOSITORY="true"
NEW_CONFIG_VERSION="3.1.1"
OLD_CONFIG_VERSION=`sed -En 's/(<Version>)([0-9].+)(<\/Version>)/\2/p' < "${PACKAGES_DIR}/config/config.xml"`
OLD_CONFIG_VERSION=`trim "${OLD_CONFIG_VERSION}"`

echo "######################################################"
echo "INSTALLER_TOOL_DIR: ${INSTALLER_TOOL_DIR}"
echo "REPO_TOOL_DIR: ${REPO_TOOL_DIR}"
echo "PACKAGES_DIR: ${PACKAGES_DIR}"
echo "REPOSITORY_DIR: ${REPOSITORY_DIR}"
echo "CREATE_OFFLINE_PACKAGE: ${CREATE_OFFLINE_PACKAGE}"
echo "CREATE_ONLINE_PACKAGE: ${CREATE_ONLINE_PACKAGE}"
echo "CREATE_NEW_REPOSITORY: ${CREATE_NEW_REPOSITORY}"
echo "UPDATE_REPOSITORY: ${UPDATE_REPOSITORY}"
echo "OLD_CONFIG_VERSION: ${OLD_CONFIG_VERSION}"
echo "NEW_CONFIG_VERSION: ${NEW_CONFIG_VERSION}"
echo "INSTALLER_NAME: ${INSTALLER_NAME}"
echo "######################################################"

COMMAND=`command -v "${INSTALLER_TOOL_DIR}/binarycreator"`
if [ -z "${COMMAND}" ]; then
  echo "binarycreator missing from ${INSTALLER_TOOL_DIR}."
  ERROR_STATUS=1
fi
COMMAND=`command -v "${INSTALLER_TOOL_DIR}/installerbase"`
if [ -z "${COMMAND}" ]; then
  echo "installerbase missing from ${INSTALLER_TOOL_DIR}."
  ERROR_STATUS=1
fi
COMMAND=`command -v "${REPO_TOOL_DIR}/repogen"`
if [ -z "${COMMAND}" ]; then
  echo "repogen missing from ${REPO_TOOL_DIR}."
  ERROR_STATUS=1
fi
if [ ! -d "${INSTALLER_TOOL_DIR}" ]; then
  echo "INSTALLER_TOOL_DIR: ${INSTALLER_TOOL_DIR}, does not exist."
  ERROR_STATUS=1
fi
if [ ! -d "${REPO_TOOL_DIR}" ]; then
  echo "REPO_TOOL_DIR: ${REPO_TOOL_DIR}, does not exist."
  ERROR_STATUS=1
fi
if [ ! -d "${PACKAGES_DIR}" ]; then
  echo "PACKAGES_DIR: ${PACKAGES_DIR}, does not exist."
  ERROR_STATUS=1
fi
if [ ! -d "${REPOSITORY_DIR}" ]; then
  if [ "${CREATE_NEW_REPOSITORY}" = "true" -o  "${UPDATE_REPOSITORY}" = "true" ]; then
    echo "REPOSITORY_DIR: ${REPOSITORY_DIR}, does not exist."
    ERROR_STATUS=1
  fi
fi

if [ $ERROR_STATUS -ne 0 ]; then
  echo "Found errors and cannot continue!"
  exit 1
else
  echo "No errors found."
fi

echo "Updating config version from ${OLD_CONFIG_VERSION} to ${NEW_CONFIG_VERSION}"
sed -Ei 's/(<Version>)([0-9].+)(<\/Version>)/\1'"${NEW_CONFIG_VERSION}"'\3/' "${PACKAGES_DIR}/config/config.xml"
if [ ! $? -eq 0 ]; then
  echo "Previous command encountered an error!"
  exit 1
fi

if [ "${CREATE_OFFLINE_PACKAGE}" = "true" ]; then
  FINAL_INSTALLER_NAME=`echo "${INSTALLER_NAME}" | sed -En 's/@installertype@/offline/p'`
  FINAL_INSTALLER_NAME="${HOME}/${FINAL_INSTALLER_NAME}"
  echo "Creating offline install ${FINAL_INSTALLER_NAME}"
  "${INSTALLER_TOOL_DIR}/binarycreator" --offline-only -t "${INSTALLER_TOOL_DIR}/installerbase" -p "${PACKAGES_DIR}/packages" -c "${PACKAGES_DIR}/config/config.xml" "${FINAL_INSTALLER_NAME}"
fi
if [ ! $? -eq 0 ]; then
  echo "Previous command encountered an error!"
  exit 1
fi
if [ "${CREATE_ONLINE_PACKAGE}" = "true" ]; then
  FINAL_INSTALLER_NAME=`echo "${INSTALLER_NAME}" | sed -En 's/@installertype@/online/p'`
  FINAL_INSTALLER_NAME="${HOME}/${FINAL_INSTALLER_NAME}"
  echo "Creating online install ${FINAL_INSTALLER_NAME}"
  "${INSTALLER_TOOL_DIR}/binarycreator" -t "${INSTALLER_TOOL_DIR}/installerbase" -p "${PACKAGES_DIR}/packages" -c "${PACKAGES_DIR}/config/config.xml" -n "${FINAL_INSTALLER_NAME}"
fi
if [ ! $? -eq 0 ]; then
  echo "Previous command encountered an error!"
  exit 1
fi

if [ "${CREATE_NEW_REPOSITORY}" = "true" ]; then
  echo "Creating new repository at ${REPOSITORY_DIR}"
  "${INSTALLER_TOOL_DIR}/repogen" -p "${PACKAGES_DIR}/packages" "${REPOSITORY_DIR}"
else
  if [ "${UPDATE_REPOSITORY}" = "true" ]; then
    echo "Updating repository at ${REPOSITORY_DIR}"
    "${INSTALLER_TOOL_DIR}/repogen" -p "${PACKAGES_DIR}/packages" --update "${REPOSITORY_DIR}"
  fi
fi
if [ ! $? -eq 0 ]; then
  echo "Previous command encountered an error!"
  exit 1
fi

exit 0
