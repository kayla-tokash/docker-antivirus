#!/bin/bash
files=$(shopt -s nullglob dotglob; echo /data/av/queue/*)
if (( ${#files} ))
then
    printf "Found files to process\n"
    for file in "/data/av/queue"/* ; do
        filename=`basename "$file"`
        # inotify sends false positives under some circumstances
        # check the file size difference to be safe
        size_start=$(du "$file" | awk '{print $1}')
        sleep 5
        size_now=$(du "$file" | awk '{print $1}')
        if [[ "$size_start" -ne "$size_now" ]]
        then
            printf "Cannot not process file, '$filename'. It seems to be open."
            continue
        fi
        mv -f "$file" "/data/av/scan/${filename}"
        printf "Processing /data/av/scan/${filename}\n"
        /usr/local/bin/scanfile.sh > /data/av/scan/info 2>&1
        if [ -e "/data/av/scan/${filename}" ]
        then
            printf "  --> File ok\n"
            mv -f "/data/av/scan/${filename}" "/data/av/ok/${filename}"
            printf "  --> File moved to /data/av/ok/${filename}\n"
            rm /data/scan/info
        elif [ -e "/data/av/quarantine/${filename}" ]
        then
            printf "  --> File quarantined / nok\n"
            mv -f "/data/av/scan/info" "/data/av/nok/${filename}"
            printf "  --> Scan report moved to /data/av/nok/${filename}\n"
        fi
    done
    printf "Done with processing\n"
fi
