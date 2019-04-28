#!/bin/bash
romdir=$(pwd)
framedir=$(pwd)/system/framework
appdir=$(pwd)/system/app
privdir=$(pwd)/system/priv-app
tools=$(pwd)/tools
oat2dex=$(ls $tools | grep oat2dex)
echo "-            Deodexer for Linux             -"
sleep 1
clear

if [[ -f $romdir/system/build.prop ]]; then
	api=""
	androidversion=$(cat $romdir/system/build.prop | grep "ro.build.version.release" | sed 's/ro\.build\.version\.release=//')
	if (( $(echo "$androidversion 7.1" | awk '{print ($1 >= $2)}') && $(echo "$androidversion 7.1" | awk '{print ($1 <= $2)}') )); then
		export api=25
	elif (( $(echo "$androidversion 7.0" | awk '{print ($1 >= $2)}') && $(echo "$androidversion 7.0" | awk '{print ($1 <= $2)}') )); then
		export api=24
	elif (( $(echo "$androidversion 6.0.1" | awk '{print ($1 >= $2)}') && $(echo "$androidversion 6.0.1" | awk '{print ($1 <= $2)}') )); then
		export api=23
	elif (( $(echo "$androidversion 5.1" | awk '{print ($1 >= $2)}') && $(echo "$androidversion 5.1" | awk '{print ($1 <= $2)}') )); then
		export api=22
	else	
		echo "Sorry, this tool only supports deodexing Lollipop."
		echo ""
		read -p "Press ENTER to exit"
		exit
	fi
else
	api=""
	while [[ $api -lt "21" || $api -gt "25" ]] ; do
		echo ""
		echo "Type the API level of the ROM and press ENTER."
		read api
		clear
	done
fi

arch=""
cd $framedir
arch="arm"

echo "Android version: $androidversion"
echo "API level: $api"
echo "ARCH: $arch" 
echo ""
read -n 1 -p "Deodex ROM? y/n?"
echo ""
echo ""
if [[ $REPLY = "y" ]]; then
	clear
else
	exit
fi

cd $tools
if [ ! -d "$framedir/oat/arm/" ]; then
	java -Xmx512m -jar $oat2dex boot $framedir/oat/arm/boot.oat > /dev/null 2>&1
fi

echo "Start deodexing /system/app ..."

cd $tools
app=""
for app in $( ls $appdir ); do
	if [[ $(7za l $appdir/$app/$app.apk | grep classes) = "" ]]; then
		if [ -d "$appdir/$app/$arch" ]; then
			echo "Deodexing - $app"
			echo " "
			java -Xmx512m -jar $oat2dex $appdir/$app/$arch/$app.odex $framedir/$arch/odex > /dev/null 2>&1
			mv $appdir/$app/$arch/$app.dex $appdir/$app/$arch/classes.dex
			if [ -f "$appdir/$app/$arch/$app-classes2.dex" ]; then
				mv $appdir/$app/$arch/$app-classes2.dex $appdir/$app/$arch/classes2.dex
			fi
			if [ -f "$appdir/$app/$arch/$app-classes3.dex" ]; then
				mv $appdir/$app/$arch/$app-classes3.dex $appdir/$app/$arch/classes3.dex
			fi
			7za u -tzip $appdir/$app/$app.apk $appdir/$app/$arch/classes*.dex > /dev/null 2>&1
			rm -rf $appdir/$app/$arch
		else 
			echo "$app - is already deodexed"
			echo " "
		fi
	else
		echo "$app - is already deodexed"
		echo " "
		rm -rf $appdir/$app/$arch
	fi
done

echo "Start deodexing /system/priv-app ..."

cd $tools
privapp=""
for privapp in $( ls $privdir ); do
	if [[ $(7za l $privdir/$privapp/$privapp.apk | grep classes) = "" ]]; then
		if [ -d "$privdir/$privapp/$arch" ]; then
			echo "Deodexing - $privapp"
			echo " "
			java -Xmx512m -jar $oat2dex $privdir/$privapp/$arch/$privapp.odex $framedir/$arch/odex > /dev/null 2>&1
			mv $privdir/$privapp/$arch/$privapp.dex $privdir/$privapp/$arch/classes.dex
			if [ -f "$privdir/$privapp/$arch/$privapp-classes2.dex" ]; then
				mv $privdir/$privapp/$arch/$privapp-classes2.dex $privdir/$privapp/$arch/classes2.dex
			fi
			if [ -f "$privdir/$privapp/$arch/$privapp-classes3.dex" ]; then
				mv $privdir/$privapp/$arch/$privapp-classes3.dex $privdir/$privapp/$arch/classes3.dex
			fi
			7za u -tzip $privdir/$privapp/$privapp.apk $privdir/$privapp/$arch/classes*.dex > /dev/null 2>&1
			rm -rf $privdir/$privapp/$arch
		else 
			echo "$privapp - is already deodexed"
			echo " "
		fi
	else
		echo "$privapp - is already deodexed"
		echo " "
		rm -rf $privdir/$privapp/$arch
	fi
done
echo "Deodexing complete"
read -p ""
