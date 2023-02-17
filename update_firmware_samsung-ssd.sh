#!/bin/bash
#
# Update Samsung firmware on SSD/NVMe drives on current Linux system
#
# Firmware ISOs can be found on Samsung's website:
#   Firmware / Samsung SSD Firmware
#   https://semiconductor.samsung.com/consumer-storage/support/tools/
#
# Multiple firmware ISOs can be run serially if multiple ISO files are
#   downloaded into the same directory listed below.
#
# User needs sudo permission to mount ISO and run fumagician binary
#
# Author takes no responsibility for Samsung firmware update software,
#   including but not limited to potential loss of data during firmware
#   update process.
# No validation/error checking is done for user defined directory names.
#
###########################################
# Use of this script is at your own risk. #
###########################################
#
# Written by Jason Woods <emonkia@gmail.com>
# Released on Github:
#   https://github.com/emonkfu/firmware_samsung-ssd/

# base directory to find Samsung firmware ISO files (named Samsung*.iso)
DIR_ISO="${HOME}/Downloads"

# base directory to place firmware update files
#   User needs write permission to this directory to create subdirectories
#   Below directories will be automatically created based on ISO file name
#     DIR_TMP/FIRMWARE.mount : ISO mount
#     DIR_TMP/FIRMWARE.bin   : binaries extracted
DIR_TMP="/dev/shm"

# show verbose output of programs? blank/null=no anything=yes
VERBOSE=

# below should not need changed unless Samsung changes how they build ISO
# binary to update driver
MAGICIAN_BIN="fumagician"
# directory to find binary
MAGICIAN_DIR="root/fumagician"

cd "${DIR_TMP}"
for FIRMWARE in $(cd "${DIR_ISO}" ; ls Samsung*.iso)
do
  echo
  echo "## Firmware = ${FIRMWARE}"
  echo
  mkdir ${VERBOSE:+-v} -p "${FIRMWARE}.mount" "${FIRMWARE}.bin"
  sudo mount -o loop "${DIR_ISO}/${FIRMWARE}" "${FIRMWARE}.mount"
  pushd "${FIRMWARE}.bin/"
  echo "## Extracting firmware binary"
  gzip -dc ../"${FIRMWARE}.mount"/initrd | \
    cpio ${VERBOSE:+-v} -id --no-absolute-filenames "${MAGICIAN_DIR}/*"
  sudo umount ../"${FIRMWARE}.mount"
  rmdir ${VERBOSE:+-v} ../"${FIRMWARE}.mount"
  # check for update binary directory
  if [ ! -d "${MAGICIAN_DIR}" ] ; then
    # binary directory not found
    echo "### ERROR: Firmware \"${FIRMWARE}\""
    echo "#   Binary directory \"${MAGICIAN_DIR}\" not found."
  else
    mv ${VERBOSE:+-v} "${MAGICIAN_DIR}"/* .
    rmdir ${VERBOSE:+-v} -p "${MAGICIAN_DIR}"
    echo
    read -p "Hit [ENTER] to continue, Ctrl-C to quit."
    echo
    if [ ! -s "${MAGICIAN_BIN}" ] ; then
      # binary file not found from expected directory (or size zero)
      echo "### ERROR: Firmware \"${FIRMWARE}\""
      echo "#   Binary \"${MAGICIAN_BIN}\" not found."
    else
      if [ ! -x "${MAGICIAN_BIN}" ] ; then
        # binary file somehow does not have execute flag from ISO
        echo "### ERROR: Firmware \"${FIRMWARE}\""
        echo "#   Binary \"${MAGICIAN_BIN}\" not executable."
      else
        # looks good, execute binary via sudo
        sudo ./"${MAGICIAN_BIN}"
      fi
    fi
  fi
  popd
done

