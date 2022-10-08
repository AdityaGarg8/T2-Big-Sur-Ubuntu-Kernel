#!/bin/bash
#upgrading script apple linux T2 Kernel

if [ $USER != root ]
then
sudo chmod 755 $0
sudo $0 $1
exit 0
fi

set -e

cd /tmp

latest=$(curl -sL https://github.com/andersfugmann/T2-Debian-Kernel/releases/latest/ | grep "<title>Release" | awk -F " " '{print $2}' )

if [[ ${#latest} = 7 ]]
then
latestkver=$(echo $latest | cut -d "v" -f 2 | cut -d "-" -f 1 | awk '{print $1".0-1"}')
latestk=$(echo $latest | cut -c 2- | cut -d "-" -f 1 | awk '{print $1".0-t2"}')
else
latestkver=$(echo $latest | cut -d "v" -f 2)
latestk=$(echo $latest | cut -c 2- | cut -d "-" -f 1 | awk '{print $1"-t2"}')
fi

currentk=$(uname -r)
existingK=($(dpkg --list | grep linux-image- | grep 't2\|mbp' | cut -d ' ' -f 2-3 ))
if [ \( $latestk != $currentk \) ]; then
	
	echo "Downloading new kernel $latest"
	curl -L https://github.com/andersfugmann/T2-Debian-Kernel/releases/download/${latest}/linux-headers-${latestk}_${latestkver}_amd64.deb > headers.deb
	curl -L https://github.com/andersfugmann/T2-Debian-Kernel/releases/download/${latest}/linux-image-${latestk}_${latestkver}_amd64.deb > image.deb

	if [ -f headers.deb -a -f image.deb ]; then
		#install
		echo "Installing new kernel $latest"
		apt install ./headers.deb
		apt install ./image.deb
		#shutdown -r 02:00 "reboot scheduled for the next 2am to update runnning kernel"
		rm -f headers.deb image.deb

		#uninstall old t2 kernels but preserve current version as a backup
		for kernel in "${existingK[@]}"
		do
			if [ \( $kernel != linux-image-$currentk \) ]; then
				echo "$kernel needs to be removed"
				version=${kernel/#linux-image-}
				#purge old t2 kernel
				dpkg -P linux-headers-$version
				dpkg -P linux-image-$version
			fi
		done
		if [[ ($1 = --remove-current) ]]; then
			echo "Current kernel linux-image-$currentk shall also be removed"

			dpkg -P linux-headers-$currentk
			dpkg -P linux-image-$currentk
		fi
	fi
else
echo "Kernel is up to date"
fi
