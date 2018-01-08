#!/bin/bash
#
# BACKUP-SCRIPT
# by: woositng
#
# This backup script icrementally backups directories. The sources are
# configurablt and user dependent. The targets are saved in a snapshot (delta)
# style. The amount that are stored (retention) is configurable. At its core
# lies the rudimentary backup script of Mike Rubel:
# http://www.mikerubel.org/computers/rsync_snapshots/
#
# 	mm -rf backup.3
# 	mv backup.2 backup.3
# 	mv backup.1 backup.2
# 	mv backup.0 backup.1
#	rsync -a --delete --link-dest=../backup.1 source_dir/ backup.0/
#
# FOR MORE INFORMATION PLEASE VISIT: http://www.woosting.nl

: <<'TODO'
	* ADD LOGGING (for cron scheduled jobs)
	* ...
TODO


# FUNCTION DECLARATIONS:
	function fatal_error {
		echo " "
		echo -e "\033[31mFATAL ERROR:\e[0m - $1"
		date
		echo "Exiting to bash."
		echo " "
		exit 1
	}
	function target_presence_check {
		if [ -e $TARGET ]; then
			usersourcetarget_feedback
		 else
			fatal_error "Unable to find target location (medium mounted?)!"
		fi
	}
	function usersourcetarget_feedback {
		echo " "
		echo "User is: \"$USER\""
		echo "------------------"
		echo "Source: $SOURCE"
		echo "Target: $TARGET"
		echo "------------------"
	}

	
# STATIC CONFIGURATION
	RETENTION="52"					# AMOUNT OF INCREMENTS TO KEEP
#	METHOD="pull"					# NOT USED --- "push" or "pull" - to the server
#	USE_SSH="0"					# NOT USED --- "0" or "1" - to resp. not use or use an SSH connection


# DYNAMIC CONFIGURATION
	if [ "$USER" = "woosting" ]; then		# WOOSTING VARIABLES:
		SOURCE="/mnt/ch3snas/Zut"		# ABSOLUTE path to ORIGINAL directory (must exist)
		TARGET="/media/3TB/backups/Zut"		# ABSOLUTE path to DESTINATION directory (must exist)
		target_presence_check			# MEDIA PRESENCE CHECK

	elif [ "$USER" = "root" ]; then			# ROOT VARIABLES:
		SOURCE="/etc /home/woosting"		# ABSOLUTE path to ORIGINAL directory (must exist)
		TARGET="/media/backup_rpi/locals"	# ABSOLUTE path to DESTINATION directory (must exist)
		target_presence_check			# MEDIA PRESENCE CHECK
	else
		fatal_error "$USER not configured!";	# OTHER USER (should be defined above)
	fi
	DATE_CURRENT=`date '+%Y%m%d'`
	DATE_1_day_ago=`date --date="1 days ago" '+%Y%m%d'`



# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
# 				FUNCTIONS & CONFIGURATION
# 				      PROGRAM LOGIC
# vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv



# ACTUAL SYNC
# Announcing the start
	echo " "
	echo "BACKUP STARTING (retention: ${RETENTION})"
	date
	echo " "

# Snapshot rolling
	# Removing last oldest backup
		if [ ${RETENTION} -ge "1" ]; then
			echo "Snapshots are being rolled..."
			rm -rf $TARGET/backup.${RETENTION}
		fi

	# Dynamically creating the retention days (by moving/renaming)
		COUNT=${RETENTION}
		while [ $COUNT -gt 0 ]; do
			COUNT_MIN1=`expr $COUNT - 1`
			mv ${TARGET}/backup.${COUNT_MIN1} ${TARGET}/backup.${COUNT}
			let COUNT=COUNT-1
		done

# Rsyncing + Hardlink the first dir
	echo " "
	rsync -avi --delete --link-dest=../backup.1 ${SOURCE} ${TARGET}/backup.0/

# Echoing the date for referance purposes
	date
	echo " "
