#!/bedrock/bin/brsh

#Setting up user things
	awk 'BEGIN{FS=OFS=":"} /^root:/{$NF = "/bedrock/bin/brsh"} 1' /etc/passwd > /etc/new-passwd
	mv /etc/new-passwd /etc/passwd
	sed -n 's/^root:/br&/p' /etc/passwd | sed 's,:[^:]*$,:/bin/sh,' >> /etc/passwd
	sed -n 's/^root:/br&/p' /etc/shadow >> /etc/shadow
	read -p "What is your username? " NONROOTUSERNAME
	awk 'BEGIN{FS=OFS=":"} /^'"$NONROOTUSERNAME"':/{$NF = "/bedrock/bin/brsh"} 1' /etc/passwd > /etc/new-passwd
	mv /etc/new-passwd /etc/passwd

	echo "/bedrock/bin/brsh" >> /etc/shells

	#Add groups. NOTE: Arch has addgroup, not addgroup. 
	addgroup -g 0 root
	addgroup -g 5 tty
	addgroup -g 6 disk
	addgroup -g 7 lp
	addgroup -g 15 kmem
	addgroup -g 20 dialout
	addgroup -g 24 cdrom
	addgroup -g 25 floppy
	addgroup -g 26 tape
	addgroup -g 29 audio
	addgroup -g 44 video
	addgroup -g 50 staff
	addgroup -g 65534 nogroup || addgroup -g 60000 nogroup
	adduser -h / -s /bin/false -D -H man || adduser -h / -s /bin/false -D -H -G man man
	addgroup input
	addgroup utmp
	addgroup plugdev
	addgroup uucp
	addgroup kvm
	addgroup syslog
	addgroup $NONROOTUSERNAME audio
	addgroup $NONROOTUSERNAME video
	#Systemd
	adduser -h / -s /bin/false -D -H daemon || adduser -h / -s /bin/false -D -H -G daemon daemon
	adduser -h / -s /bin/false -D -H systemd-network || adduser -h / -s /bin/false -D -H -G network network
	adduser -h / -s /bin/false -D -H systemd-timesync || adduser -h / -s /bin/false -D -H -G timesync timesync
	adduser -h / -s /bin/false -D -H systemd-resolve || adduser -h / -s /bin/false -D -H -G resolve resolve
	adduser -h / -s /bin/false -D -H systemd-bus-proxy || adduser -h / -s /bin/false -D -H -G proxy proxy
	adduser -h / -s /bin/false -D -H messagebus || adduser -h / -s /bin/false -D -H -G messagebus messagebus
	adduser -h / -s /bin/false -D -H dbus || adduser -h / -s /bin/false -D -H -G dbus dbus
	addgroup daemon
	addgroup adm
	addgroup systemd-journal
	addgroup systemd-journal-remote
	addgroup systemd-timesync
	addgroup systemd-network
	addgroup systemd-resolve
	addgroup systemd-bus-proxy
	addgroup messagebus
	addgroup dbus

	exit
