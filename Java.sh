#!/bin/sh
# Determine OS version
osvers=$(sw_vers -productVersion | awk -F. '{print $2}')

# check if newer version exists
plugin="/Library/Internet Plug-Ins/JavaAppletPlugin.plugin/Contents/Info.plist"
if [ -f "$plugin" ]
then
	currentver=`/usr/bin/defaults read "/Library/Internet Plug-Ins/JavaAppletPlugin.plugin/Contents/Info.plist" CFBundleShortVersionString`
	echo " Current version is $currentver"
	currentvermain=${currentver:5:1}
	echo "Installed main version is $currentvermain"
	currentvermin=${currentver:14:3}
	echo "Installed minor version is $currentvermin"
	onlineversionmain=`curl -L http://www.java.com/en/download/manual.jsp | grep "Recommended Version" | awk '{ print $4}'`
	echo "Online main: $onlineversionmain"
	onlineversionmin1=`curl -L http://www.java.com/en/download/manual.jsp | grep "Recommended Version" | awk '{ print $6}' | awk -F "<" '{ print $1}'`
	onlineversionmin=${onlineversionmin1:0:3}
	echo "Online minor: $onlineversionmin"
	if [ -z "${currentvermain}" ] || [ "${onlineversionmain}" -gt "${currentvermain}" ]
	then
		echo "Let's install Java! Main online version is higher than installed version."
		installjava=1
	fi
	if [ "${onlineversionmain}" = "${currentvermain}" ] && [ "${onlineversionmin}" -gt "${currentvermin}" ]
	then
		echo "Let's install Java! Main online version is equal than installed version, but minor version is higher."
		installjava=1
	fi
	if [ "${onlineversionmain}" = "${currentvermain}" ] && [ "${onlineversionmin}" = "${currentvermin}" ]
	then
		echo "Java is up-to-date!"
	fi
else
	echo "No java installed, let's install"
	installjava=1
fi


# Find Download URL
fileURL=`curl -L http://www.java.com/en/download/manual.jsp | grep "Download Java for Mac OS X" | awk -F "\"" '{ print $4;exit}'`


# Specify name of downloaded disk image

java_eight_dmg="/tmp/java_eight.dmg"

if [[ ${osvers} -lt 7 ]]; then
  echo "Oracle Java 8 is not available for Mac OS X 10.6.8 or earlier."
  exit 0
fi

if [ "$installjava" = 1 ]
then
    echo "Start installing Java"
    if [[ ${osvers} -ge 7 ]]; then

        # Download the latest Oracle Java 8 software disk image

        /usr/bin/curl --retry 3 -Lo "$java_eight_dmg" "$fileURL"

        # Specify a /tmp/java_eight.XXXX mountpoint for the disk image

        TMPMOUNT=`/usr/bin/mktemp -d /Volumes/java_eight.XXXX`

        # Mount the latest Oracle Java disk image to /tmp/java_eight.XXXX mountpoint

        hdiutil attach "$java_eight_dmg" -mountpoint "$TMPMOUNT" -nobrowse -noverify -noautoopen

        # Install Oracle Java 8 from the installer package.

        if [[ -e "$(/usr/bin/find $TMPMOUNT -name *Java*.pkg)" ]]; then    
            pkg_path=`/usr/bin/find $TMPMOUNT -name *Java*.pkg`
        elif [[ -e "$(/usr/bin/find $TMPMOUNT -name *Java*.mpkg)" ]]; then    
            pkg_path=`/usr/bin/find $TMPMOUNT -name *Java*.mpkg`
        fi

        # Before installation, the installer's developer certificate is checked 

        if [[ "${pkg_path}" != "" ]]; then
                echo "installing Java from ${pkg_path}..."
                /usr/sbin/installer -dumplog -verbose -pkg "${pkg_path}" -target "/" > /dev/null 2>&1

        fi

        # Clean-up

        # Unmount the disk image from /tmp/java_eight.XXXX

        /usr/bin/hdiutil detach -force "$TMPMOUNT"

        # Remove the /tmp/java_eight.XXXX mountpoint

        /bin/rm -rf "$TMPMOUNT"

        # Remove the downloaded disk image

        /bin/rm -rf "$java_eight_dmg"

        # Remove xml file
        /bin/rm -rf /tmp/au-1.8.0_20.xml
    fi
fi
