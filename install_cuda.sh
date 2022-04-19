#!/bin/bash
# Installation script for CUDA >= 10 (no root required)

# set -x
# trap read debug

function Help()
{
    # Display Help
    title "SYNOPSIS"
    echo "    ${0} <CUDA_VERSION_MAJOR> <CUDA_VERSION_MINOR> <DRIVER_VERSION> <OPTIONAL_INSTALL_LOCATION> ..."
    echo ""
    title "DESCRIPTION"
    echo "    Local CUDA installation script for CUDA >= 10"
    echo ""
    title "OPTIONS"
    echo "    -h, --help                    Print this help"
    echo ""
}

CUDA_INSTALL_DIR="/usr/local/cuda/${CUDA_VERSION}"

# Adapt the following version numbers according to your needs
CUDA_VERSION_MAJOR="${1}"
CUDA_VERSION_MINOR="${2}"
DRIVER_VERSION="${3}"
IFS='.' read -ra CUDA_MAIN_VERSION <<< "$CUDA_VERSION_MAJOR"

if [[ ! -z "${4}" ]]; then
    CUDA_INSTALL_DIR="${4}"
fi

if [[ -z "${1}" ]] || [[ -z "${3}" ]]; then
    echo
    echo "ERROR: Missing parameter(s)!"
    echo
    echo "Usage: ${0} <CUDA_VERSION_MAJOR> <CUDA_VERSION_MINOR> <DRIVER_VERSION> <OPTIONAL_INSTALL_LOCATION>"
    echo "Example: ${0} 10.0 130 410.48 /usr/local/cuda/10.0"
    echo "Example: ${0} 11.0.2 "" 450.51.05 /usr/local/cuda/11.0"
    echo
    exit
fi

while getopts "h" option; do
    case $option in
        h) # display Help
            Help
            exit;;
    esac
done

TMPDIR="$(dirname ${CUDA_INSTALL_DIR})/tmp"
mkdir -p "${CUDA_INSTALL_DIR}" "${TMPDIR}"

# Handle special case for CUDA 10.0
if [ $((CUDA_MAIN_VERSION[0])) -eq 10 ] && [ $((CUDA_MAIN_VERSION[1])) -eq 0 ]; then
    CUDA_VERSION="${CUDA_VERSION_MAJOR}.${CUDA_VERSION_MINOR}_${DRIVER_VERSION}"
    CUDA_INSTALLER="cuda_${CUDA_VERSION}_linux"
elif [ $((CUDA_MAIN_VERSION[0])) -gt 10 ]; then
    CUDA_VERSION="${CUDA_VERSION_MAJOR}_${DRIVER_VERSION}"
    CUDA_INSTALLER="cuda_${CUDA_VERSION}_linux.run"
else
    CUDA_VERSION="${CUDA_VERSION_MAJOR}.${CUDA_VERSION_MINOR}_${DRIVER_VERSION}"
    CUDA_INSTALLER="cuda_${CUDA_VERSION}_linux.run"
fi

if [[ ! -f "${TMPDIR}/${CUDA_INSTALLER}" ]]; then
    # Handle special case for CUDA 10.0
    if [ $((CUDA_MAIN_VERSION[0])) -eq 10 ] && [ $((CUDA_MAIN_VERSION[1])) -eq 0 ]; then
        wget "http://developer.nvidia.com/compute/cuda/${CUDA_VERSION_MAJOR}/Prod/local_installers/${CUDA_INSTALLER}" -O "${TMPDIR}/${CUDA_INSTALLER}"
    elif [ $((CUDA_MAIN_VERSION[0])) -gt 10 ]; then
        wget "http://developer.download.nvidia.com/compute/cuda/${CUDA_VERSION_MAJOR}/local_installers/${CUDA_INSTALLER}" -O "${TMPDIR}/${CUDA_INSTALLER}"
    else
        wget "http://developer.download.nvidia.com/compute/cuda/${CUDA_VERSION_MAJOR}/Prod/local_installers/${CUDA_INSTALLER}" -O "${TMPDIR}/${CUDA_INSTALLER}"
    fi
fi

if [[ ! -x "${TMPDIR}/${CUDA_INSTALLER}" ]]; then
    chmod 700 "${TMPDIR}/${CUDA_INSTALLER}"
fi

echo 'Installing, please be patient.'

if [ $((CUDA_MAIN_VERSION[0])) -gt 10 ]; then
    EXEC_CMD="${TMPDIR}/${CUDA_INSTALLER} --silent --override --toolkit --toolkitpath=${CUDA_INSTALL_DIR} --no-man-page --tmpdir=${TMPDIR}"
else
    EXEC_CMD="${TMPDIR}/${CUDA_INSTALLER} --silent --override --toolkit --installpath=${CUDA_INSTALL_DIR} --toolkitpath=${CUDA_INSTALL_DIR} --no-man-page --tmpdir=${TMPDIR}"
fi

if ${EXEC_CMD}; then
    echo 'Done.'
    echo
    echo "To use CUDA Toolkit ${CUDA_VERSION_MAJOR}.${CUDA_VERSION_MINOR}, extend your environment as follows:"
    echo

    if [[ -z ${PATH} ]]; then
        echo "export PATH=${CUDA_INSTALL_DIR}/bin"
    else
        echo "export PATH=${CUDA_INSTALL_DIR}/bin:\${PATH}"
    fi

    if [[ -z ${LD_LIBRARY_PATH} ]]; then
        echo "export LD_LIBRARY_PATH=${CUDA_INSTALL_DIR}/lib64"
    else
        echo "export LD_LIBRARY_PATH=${CUDA_INSTALL_DIR}/lib64:\${LD_LIBRARY_PATH}"
    fi
else
    cat /tmp/cuda-installer.log
    echo
    echo "Error installing CUDA ${CUDA_VERSION_MAJOR}!"
fi
