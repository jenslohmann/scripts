#!/usr/bin/env bash

# Brug:
# ./followMiljoe.sh <miljoe>

miljoe=${1:-preprod}

# Flg. skal defineres i filen followEnv:
# - systemer
# - mountpoint
# Flg. KAN defineres i filen:
# - miljoe (fx dev, test, preprod, prod) eller kan angives som parameter
# Flg. SKAL defineres i filen, hvis mountpoint skal etableres af scriptet:
# - sambabruger
# - sambapassword
# - sambadrev
. followEnv

if [ -z "${systemer}" ] || [ -z "${mountpoint}" ]; then
    exit 1
fi

command=newWindow
idag=$(date +%Y-%m-%d)

newWindow() {
    osascript 2>/dev/null <<-EOF
	tell application "System Events"
		tell process "Terminal" to keystroke "n" using command down
	end
	tell application "Terminal"
	activate
	do script with command "$1" in window 1
	end tell
	EOF
}

newTab() {
    osascript 2>/dev/null <<-EOF
	tell application "System Events"
		tell process "Terminal" to keystroke "t" using command down
	end
	tell application "Terminal"
	activate
	do script with command "$1" in window 1
	end tell
	EOF
}

tailSystem() {
    rod=$1
    system=$2
    folder=${mountpoint}/${system}
    pushd ${folder} > /dev/null
    maskiner=$(ls -d ${miljoe}*)
    popd > /dev/null

    echo ${maskiner}

    for maskine in ${maskiner}; do
        postfix=$(echo ${maskine}|cut -d- -f3)
        ${command} "tail -F ${folder}/${maskine}/${system}.${idag}.log > ${rod}/${system}.${idag}.${postfix}.log"
        command=newTab
    done
}

if [ ! -d "${mountpoint}" ]; then
    sudo mkdir ${mountpoint}
    sudo chown ${USER} ${mountpoint}
    mount -t smbfs ${sambadrev} ${mountpoint}
fi

rod="${HOME}/ERST/${miljoe}"

if [ ! -d "${rod}" ]; then
    mkdir ${rod}
fi

for system in ${systemer}; do
    tailSystem ${rod} ${system}
done

