#!/bin/bash
#
# Script to create a DMG from build App.
#
# The script creates a dmg from new app,
# code signes the .dmg file
#
# Bartosz Swiatek
# (c) Smart Mobile Factory
#
# 04.09.2018

#set -x
set -e

PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH
export PATH

#
# Setup
#

CODE_SIGN_ID=
USE_TEMPLATE=

#
# Variables
#

APPPATH=""
TEMPLATE_PATH=""

#
# Helper
#

function usage() {
    echo "Script to create a DMG from .app"
    echo
    echo "Required parameters:"
    echo -e "--appPath, -p\t\t: Path to the .app"
    echo
    echo "Optional"
    echo -e "--codesignid, -ci\t: Code signing identity, required if --codesign or -cs was used"
    echo -e "--template, -t\t\t: Build the DMG from a template. If not specified, DMG will be created without a template"
    echo
    exit 0
}

#
# Main Loop
#

while [ $# -gt 0 ]; do
    case "$1" in
        --appPath | -p)
            # Path where the App is stored after a successful build
            APPPATH="$2"
            shift 2
        ;;
        --codesignid | -ci)
            CODE_SIGN_ID=$2
            shift 2
        ;;
        --template | -t)
            TEMPLATE_PATH=$2
            USE_TEMPLATE="true"
            shift 2
        ;;
        -*)
            usage
        ;;
        *)
    esac
done

if [ -z "$APPPATH" ]; then
    usage
fi

if [ "$USE_TEMPLATE" = "true" ] && [ -z "$TEMPLATE_PATH" ]; then
    usage
fi

INFO_PLIST="$APPPATH"/Contents/Info.plist
NAME=$(defaults read "$INFO_PLIST" CFBundleName)
VOLNAME=$NAME
VERSION=$(defaults read "$INFO_PLIST" CFBundleShortVersionString)
SHORT_VERSION=$(defaults read "$INFO_PLIST" CFBundleVersion)
APPDIR=$(dirname "$APPPATH")
APPVERSION=${VERSION}-${SHORT_VERSION}
APPFULLNAME=${NAME}-${APPVERSION}

#
# DMG
#

if [ "$USE_TEMPLATE" = "true" ]; then
    cd "${APPDIR}"
    
    # Copy template
    cp "${TEMPLATE_PATH}" "${APPDIR}"/template.dmg
    
    # Convert template
    hdiutil convert -format UDSB -o templateWritable.dmg template.dmg
    
    # Get app size
    APP_SIZE=$(du -sm "${APPPATH}" | egrep -o '[[:digit:]]*')
    
    # We add a buffer to be on the safe side
    APP_SIZE_WITH_BUFFER=$((${APP_SIZE} + 20))
    
    # Resize template
    hdiutil resize -size ${APP_SIZE_WITH_BUFFER}M templateWritable.dmg.sparsebundle
    
    # Mount bundle - Returns path to Volume (the Volume name can have spaces, dashes, digits and other chars, so the regex covers basically all)
    ORIGINAL_SPARSE_VOLUME_PATH=$(hdiutil attach templateWritable.dmg.sparsebundle | egrep -o '/Volumes/(.*?)+$')
    
    # Make sure there is nothing mounted at ${VOLNAME} (`|| :` is there to make sure the command can fail without interrupting the script)
    hdiutil detach /Volumes/"${VOLNAME}" || :
    
    sleep 1
    
    # Rename Volume
    diskutil rename "${ORIGINAL_SPARSE_VOLUME_PATH}" "${VOLNAME}"
    
    sleep 1
    
    # Empty dummy app content
    rm -fr "/Volumes/${VOLNAME}/HiDrive.app/*"
    
    # Replace dummy app with real content - TODO: call the dummy app something generic
    ditto "${APPPATH}" "/Volumes/${VOLNAME}/HiDrive.app"
    
    sleep 1
    
    # Rename app
    mv "/Volumes/${VOLNAME}/HiDrive.app" "/Volumes/${VOLNAME}/${NAME}.app"
    
    sleep 1
    
    # Detach
    hdiutil detach /Volumes/"${VOLNAME}"
    
    sleep 1
    
    # Compact sparse bundle
    hdiutil compact templateWritable.dmg.sparsebundle
    
    sleep 1
    
    # Convert to final form
    hdiutil convert -format UDZO -o "${NAME}".dmg templateWritable.dmg.sparsebundle
    
    sleep 1
    
    # Cleanup
    rm template.dmg
    rm -fr templateWritable.dmg.sparsebundle
else
    # WITHOUT TEMPLATE
    SRCFOLDER="${APPDIR}"/"${APPFULLNAME}"
    
    rm -rf "${SRCFOLDER}"
    mkdir -p "${SRCFOLDER}"
    cp -R "${APPPATH}" "${SRCFOLDER}"
    cd "${SRCFOLDER}"
    ln -s /Applications .
    cd ..
    hdiutil create "${NAME}".dmg -fs HFS+ -format UDZO -volname "${VOLNAME}" -srcfolder "${SRCFOLDER}"
fi

if [ $? -gt 0 ]; then
    echo "Abort: Error creating DMG"
    exit 1
fi

#
# Code Sign
#

if [ -n "$CODE_SIGN_ID" ]; then
    codesign -s "$CODE_SIGN_ID" "${APPDIR}"/"${NAME}".dmg
    if [ $? -gt 0 ]; then
        echo "Abort: Error code signing the DMG"
        exit 1
    fi
fi

# check if signed correctly
# spctl -a -t open --context context:primary-signature -v MyImage.dmg

echo "Done."
