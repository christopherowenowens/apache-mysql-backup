#!/bin/bash

# Webserver Backup script for reala.io
# Owen 2021-09-26 "That's no moon"

# This script will backup each directory in /var/www and create a .tar.gz in the
# user-defined Backup Directory. It will then dump all mysql database arrays as
# well, skipping the meta tables. It creates a log file, and will email it to you
# provided you have email setup (see SASL email setup).

# TODO: 
    
    # Backup Apache site definitions 
    # Backup Apache traffic log per var/log/apache2 backup


# Housekeeping: Variables scoped outside of function since needed for logs.

    # User defined
    TARGETDIR="/var/www"
    BACKUPDIR="/home/user/backups/"
    #APACHELOGDIR="/var/log/apache2"
    #APACHESITESAVAIL="/etc/apache2/sites-available"
    #APACHESITESENABLED="/etc/apache2/sites-enabled"

    # Script defined
    currentDate=`date -I` # ISO 8601
    currentTime=`date +%H%M%S`
    logDir="${BACKUPDIR}/backup-logs/"
    logFile="${logDir}/${currentDate}-${currentTime}-backup.log"
    fullLogFile="${logDir}/full-backup.log"
    lastLogFile="${logDir}/last-backup.log"


# Log Directory check / creation
# Must be done before calling the function for first time; otherwise the 'tee' doesn't work first run

    # Silently create dirs and logs if they don't already exist

    if ! [ -d $logDir ]; then
        mkdir $logDir
    fi

    if ! [ -f "$logFile" ]; then
        touch $logFile
    fi

    if ! [ -f "$fullLogFile" ]; then
        touch $fullLogFile
    fi

    # Required to bounce for ANSI escape sequence cleanup
    if ! [ -f "$lastLogFile" ]; then
        touch $lastLogFile
    fi




# The script is mostly a single function, defined here, which is then called at the end and tee'd to a log.

# main function definition
realaWebBackup() {


    # Header
    clear
    echo "### backup.sh - Web Backup Script ###"
    echo "Created by Christopher \"Owen\" Owens"
    echo "Timestamp: $currentDate $currentTime"
    echo "" # blank line



    # Backup webdirs

        # Inform
        echo "Backing up webdirs..."

        # For each file loop
        for site in "$TARGETDIR"/*/; do

            # get basename
            base=$(basename "$site")
     
            # Inform
            echo -n "Backing up $site ... "

            # ensure each time you cd to dir for additional security
            # create tar gz with prepended date in backupdir, based on 'base' name
            # This is pretty failproof; no error checking needed
            ( cd "$TARGETDIR" && tar -zcf "$BACKUPDIR/$(date +%F)_$base.tar.gz" "$base" )
        
            echo "Done."

        done

        # Timing
	echo
        echo -n "Finished backing up webdirs at " && echo `date +%H%M%S`
	echo



    # Backup SQL
       # Inform
        echo "Backing up SQL databases..."

        # Move to backup directory
        cd $BACKUPDIR

        # Get array of all DB by passing command, trimming
        databases=`mysql -e "SHOW DATABASES;" | tr -d "| " | grep -v Database`

        # Skip unnecessary DBs; for each, backup with date tag. Will echo errors.
        for db in $databases; do
            if [[ "$db" != "information_schema" ]] && [[ "$db" != "performance_schema" ]] && [[ "$db" != "mysql" ]] && [[ "$db" != _* ]] ; then
                echo "Dumping database: $db"
                mysqldump --databases $db > `date +%F`.$db.sql
            fi
        done

        echo -n "Finished backing up SQL at " && echo `date +%H%M%S`



    # Backup apache logs
    # TODO

    # Backup sites-avail configs
    # TODO

    # Success! Log end time 
    finishTime=`date +%H%M%S`
    echo "Finished full backup at $finishTime"
    return 0

    }  #End main function definition



# Now, actually call the function.
# Will return to stdout as well as append (-a) to the log.
realaWebBackup | tee -a $logFile


# Lumberjacking (log cleanup)

    # Remove Ansi escape sequences - for some reason these show up in logs.
    sed "s,\x1B\[[0-9;]*[a-zA-Z],,g" $logFile > $lastLogFile
    cat $lastLogFile > $logFile

    # Append today's log to the full log
    echo "Appending today's log to the full log..."
    echo $'\n\n' >> $logFile # a little spacing for readability
    cat $logFile >> $fullLogFile



# Error handling
# $? returns the error code
    if [ $? -eq 1 ]; then
        echo "Uh-oh. Looks like something failed."
        echo "Please check the logs and try again."
    fi



# Email result
    # Email result
#    echo "Emailing $logRecipient... "
#    echo "$(<$logFile)" | mail -s "QLCHI Backup Report" owen@quantumleapchicago.com

    # Quick sanity check email log for send and append to log
#    emailLog=`tail -n 2 /var/log/mail.log | head -n 1`
#    if [[ $emailLog == *"status=sent"* ]]; then
#        echo "Email status: Looks good! Quick check of /var/log/mail.log looks like it sent ok!" >> $logFile
#    else
#        echo "Email status: Uh-oh! /var/log/mail.log indicates it may have failed sending email!" >> $logFile
#    fi




# Done
echo "Q'apla!"
