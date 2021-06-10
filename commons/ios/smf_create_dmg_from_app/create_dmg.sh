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

PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH
export PATH

#
# Setup
#

CREATE_DMG=true
CODE_SIGN_ID=
TEMPLATE_PATH=

#
# Variables
#

APPPATH=""

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
			shift
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

INFO_PLIST="$APPPATH"/Contents/Info.plist
NAME=$(defaults read "$INFO_PLIST" CFBundleName)
VOLNAME=$NAME
VERSION=$(defaults read "$INFO_PLIST" CFBundleShortVersionString)
SHORT_VERSION=$(defaults read "$INFO_PLIST" CFBundleVersion)
APPDIR=$(dirname "$APPPATH")
APPVERSION=${VERSION}-${SHORT_VERSION}
APPFULLNAME=${NAME}-${APPVERSION}
SRCFOLDER=${APPDIR}/${APPFULLNAME}

#
# DMG
#

# WITH TEMPLATE

# Copy template

# Convert template
hdiutil convert -format UDSB -o testWritable.dmg test.dmg

# Resize template
hdiutil resize -size 200M testWritable.dmg.sparsebundle

# Mount bundle - Returns path to volume

$ORIGINAL_SPARSE_VOLUME_PATH=$(hdiutil attach testWritable.dmg.sparsebundle | egrep -o '/Volumes/[a-zA-Z]+$')

# Rename Volume
diskutil rename $ORIGINAL_SPARSE_VOLUME_PATH $VOLNAME

# Empty dummy app
rm -fr /Volumes/${VOLNAME}/HiDrive.app/*

# Replace dummy app with real content - TODO: call the dummy app something generic
ditto ${APPPATH} /Volumes/${VOLNAME}/HiDrive.app

# Rename app
mv /Volumes/${VOLNAME}/HiDrive.app /Volumes/${VOLNAME}/${NAME}.app

# Detach
hdiutil detach /Volumes/${VOLNAME}

# Compact sparse bundle
hdiutil compact testWritable.dmg.sparsebundle

# Convert to final form
hdiutil convert -format UDZO -o HiDrive_Alpha.dmg testWritable.dmg.sparsebundle

# WITHOUT TEMPLATE

if [ $CREATE_DMG = true ]; then
    rm -rf "${SRCFOLDER}"
	mkdir -p "${SRCFOLDER}"
	cp -R "${APPPATH}" "${SRCFOLDER}"
	cd "${SRCFOLDER}"
	ln -s /Applications .
	cd ..
	hdiutil create "${NAME}".dmg -fs HFS+ -format UDZO -volname "${VOLNAME}" -srcfolder "${SRCFOLDER}"
	if [ $? -gt 0 ]; then
		echo "Abort: Error creating DMG"
		exit 1
	fi
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
