#!/bin/bash

if [ $(whoami) != "root" ]
then
	echo "Must install as root. Try su then ./installBedrock"
else
	#untar file
	tar xvf ./tar/bedrock_linux_1.0beta2_nyla.tar -C /
	/bedrock/libexec/setcap cap_sys_chroot=ep /bedrock/bin/brc

	#Get some info from the user
	read -p "Stratum Name: " strata
	read -p "What is your init system? " initsystem

	#Write the strata conf file
	echo "[$strata]" >> /bedrock/etc/strata.conf
	echo "framework = global" >> /bedrock/etc/strata.conf
	echo "init = $initsystem" >> /bedrock/etc/strata.conf

	#Set the defaults for booting
	echo "default_stratum = $strata" >> /bedrock/etc/brn.conf
	echo "default_cmd = $initsystem" >> /bedrock/etc/brn.conf
	echo "timeout = 10" >> /bedrock/etc/brn.conf

	#Make the aliases
	sed -i "s/<DO AT INSTALL TIME>/$strata/g" /bedrock/etc/aliases.conf
	mkdir -p /bedrock/strata/$strata
	chmod a+rx /bedrock/strata/$strata
	ln -s /$strata /bedrock/strata/rootfs
	export ROOTFS=/
	ln -s /$strata /bedrock/strata/global
	export GLOBAL=$ROOTFS
	cp scripts/userSetup.sh $GLOBAL
	cd /

	#Make some necessary directories
	for dir in dev proc sys mnt root tmp var run bin; do mkdir -p $ROOTFS/$dir; done
	[ -e $ROOTFS/bin/sh ] || ln -s /bedrock/libexec/busybox $ROOTFS/bin/sh

	#Make any files that don't already exist
	mkdir -p $GLOBAL
	cp -nrp /bedrock/global-files/* $GLOBAL
	[ -e $GLOBAL/etc/sudoers ] && echo 'Defaults secure_path="/bedrock/bin:/bedrock/sbin:/bedrock/brpath/pin/bin:/bedrock/brpath/pin/sbin:/usr/local/bin:/opt/bin:/usr/bin:/bin:/usr/local/sbin:/opt/sbin:/usr/sbin:/sbin:/bedrock/brpath/bin:/bedrock/brpath/sbin"' >> $GLOBAL/etc/sudoers
	read -p "Do you have your fstab setup already? (y/n)" fr
	if [ $fr != "y" ]
	then
		nano $GLOBAL/etc/fstab
	fi
	if [ ! \( -d /tmp && -d /var/tmp \)  ]
	then
		mkdir -p $GLOBAL/tmp $GLOBAL/var/tmp
		chmod a+rwxt $GLOBAL/tmp
		chmod a+rwxt $GLOBAL/var/tmp
	fi
	rm -r /bedrock/global-files
	[ -e "$GLOBAL/etc/adjtime" ] || printf '0.000000 0.000000 0.000000\n0\nUTC\n' > $GLOBAL/etc/adjtime

	#Skipping timezone step. This is easy enough to do manually until I can make a nice interface
	#Also skipping hostname. Setting this up is part of installing the hijack. Can always be changed later
	#skipping Linux kernel stuff because hijack
	#The echo at the end specifies what we skipped

	[ "$GLOBAL" != "$ROOTFS" ] && mkdir -p $GLOBAL/bedrock/libexec/
	[ "$GLOBAL" != "$ROOTFS" ] && cp $ROOTFS/bedrock/libexec/busybox $GLOBAL/bedrock/libexec/

	chroot $GLOBAL ./userSetup.sh

	#Bootloader
	sed -r -i 's/(GRUB_CMDLINE_LINUX=).*/\1"rw init=\/bedrock\/sbin\/brn"/g' /etc/default/grub
	sed -r -i 's/(GRUB_DISTRIBUTOR=).*/\1"Bedrock"/g' /etc/default/grub
	sed -i 's/splash/ /g' /etc/default/grub
	#Arch oriented install so the following command is used instead of update-grub
	grub-mkconfig -o  /boot/grub/grub.cfg

	echo "All done. Assuming everything went well, you only need to do the timezone thing. Check the docs for more info on that."
	echo "You can now reboot"

fi
