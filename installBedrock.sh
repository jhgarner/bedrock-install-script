#!/bin/bash

if [ $(whoami) != "root" ]
then
	echo "Must install as root. Try su then ./installBedrock"
else
	#untar file
	tar xvf ./bedrocklinux-userland/bedrock_linux_1.0beta2_nyla.tar -C /
	cd /
	/bedrock/libexec/setcap cap_sys_chroot=ep /bedrock/bin/brc

	#Get some info from the user
	read -p "Stratum Name: " strata
	read -p "What is your init system? " initsystem

	#Write the strata conf file
	echo "[$strata]" >> /bedrock/etc/strata.conf
	echo "framework = global" >> /bedrock/etc/strata.conf
	echo "init = $initsystem" >> /bedrock/etc/strata.conf

	#Set the defaults for booting
	echo "default_strataum = $strata" >> /bedrock/etc/brn.conf
	echo "default_cmd = $initsystem" >> /bedrock/etc/brn.conf
	echo "timeout = 10" >> /bedrock/etc/brn.conf

	#Make the aliases
	sed -i 's/<DO AT INSTALL TIME>/$strata/g' /bedrock/etc/aliases.conf
	mkdir -p /bedrock/strata/$strata
	chmod a+rx /bedrock/strata/$strata
	ln -s $strata /bedrock/strata/rootfs
	export ROOTFS=/
	ln -s $strata /bedrock/strata/global
	export GLOBAL=$ROOTFS

	#Make some necessary directories
	for dir in dev proc sys mnt root tmp var run bin; do mkdir -p $ROOTFS/$dir; done
	[ -e $ROOTFS/bin/sh ] || ln -s /bedrock/libexec/busybox $ROOTFS/bin/sh

	#Make any files that don't aclready exist
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
	#Skipping special fstab. If your hijack booted, you should be fine.
	#If someone who knows how the other fstabs work wants to try scripting it, go ahead.
	#skipping Linux kernel stuff because hijack
	#Finally, skipping the global stuff. Global is rootfs in this case
	#The echo at the end specifies what we skipped

	#Setting up user things
	awk 'BEGIN{FS=OFS=":"} /^root:/{$NF = "/bedrock/bin/brsh"} 1' /etc/passwd > /etc/new-passwd
	mv /etc/new-passwd /etc/passwd
	sed -n 's/^root:/br&/p' /etc/passwd | sed 's,:[^:]*$,:/bin/sh,' >> /etc/passwd
	sed -n 's/^root:/br&/p' /etc/shadow >> /etc/shadow
	read -p "What is your username? " NONROOTUSERNAME
	awk 'BEGIN{FS=OFS=":"} /^'"$NONROOTUSERNAME"':/{$NF = "/bedrock/bin/brsh"} 1' /etc/passwd > /etc/new-passwd
	mv /etc/new-passwd /etc/passwd

	#Add groups. NOTE: Arch has groupadd, not addgroup. 
	groupadd -g 0 root
	groupadd -g 5 tty
	groupadd -g 6 disk
	groupadd -g 7 lp
	groupadd -g 15 kmem
	groupadd -g 20 dialout
	groupadd -g 24 cdrom
	groupadd -g 25 floppy
	groupadd -g 26 tape
	groupadd -g 29 audio
	groupadd -g 44 video
	groupadd -g 50 staff
	groupadd -g 65534 nogroup || groupadd -g 60000 nogroup
	useradd -h / -s /bin/false -D -H man || adduser -h / -s /bin/false -D -H -G man man
	groupadd input
	groupadd utmp
	groupadd plugdev
	groupadd uucp
	groupadd kvm
	groupadd syslog
	groupadd $NONROOTUSERNAME audio
	groupadd $NONROOTUSERNAME video
	#Systemd
	useradd -h / -s /bin/false -D -H daemon || useradd -h / -s /bin/false -D -H -G daemon daemon
	useradd -h / -s /bin/false -D -H systemd-network || useradd -h / -s /bin/false -D -H -G network network
	useradd -h / -s /bin/false -D -H systemd-timesync || useradd -h / -s /bin/false -D -H -G timesync timesync
	useradd -h / -s /bin/false -D -H systemd-resolve || useradd -h / -s /bin/false -D -H -G resolve resolve
	useradd -h / -s /bin/false -D -H systemd-bus-proxy || useradd -h / -s /bin/false -D -H -G proxy proxy
	useradd -h / -s /bin/false -D -H messagebus || useradd -h / -s /bin/false -D -H -G messagebus messagebus
	useradd -h / -s /bin/false -D -H dbus || useradd -h / -s /bin/false -D -H -G dbus dbus
	groupadd daemon
	groupadd adm
	groupadd systemd-journal
	groupadd systemd-journal-remote
	groupadd systemd-timesync
	groupadd systemd-network
	groupadd systemd-resolve
	groupadd systemd-bus-proxy
	groupadd messagebus
	groupadd dbus
	groupadd netdev
	groupadd bluetooth
	groupadd optical
	groupadd storage
	groupadd lock
	groupadd uuidd

	#Exit here if we were doing that

	#Bootloader
	sed -r -i 's/(GRUB_CMDLINE_LINUX=).*/\1"rw init=\/bedrock\/sbin\/brn"/g' /etc/default/grub
	sed -r -i 's/(GRUB_DISTRIBUTOR=).*/\1"Bedrock"/g' /etc/default/grub
	sed -i 's/splash/ /g' /etc/default/grub
	#Arch oriented install so the following command is used instead of update-grub
	grub-mkconfig -o  /boot/grub/grub.cfg

	echo "All done. Assuming everything went well, you only need to do the timezone thing. Check the docs for more info on that."
	echo "You can now reboot"

fi
