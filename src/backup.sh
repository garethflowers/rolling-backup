#!/bin/bash
set -e

# OPTS

SRC=$1
DEST=$2
JOBNAME=$3
LOGS=$DEST/logs
HOSTNAME=$( hostname )

[ -z $SRC ]     && echo "No source set!" && exit 1
[ -z $DEST ]    && echo "No destination set!" && exit 1

[ -z $JOBNAME ] && JOBNAME=backup
[ -f $DEST ] && rm -f $DEST
[ ! -d $DEST ]  && mkdir -p $DEST
[ ! -d $LOGS ]  && mkdir -p $LOGS

# ROTATE

[ -d $DEST/$JOBNAME.3 ]     && rm --recursive --force $DEST/$JOBNAME.3
[ -f $LOGS/$JOBNAME.3.log ] && rm --force $LOGS/$JOBNAME.3.log
[ -d $DEST/$JOBNAME.2 ]     && mv $DEST/$JOBNAME.2 $DEST/$JOBNAME.3
[ -f $LOGS/$JOBNAME.2.log ] && mv $LOGS/$JOBNAME.2.log $LOGS/$JOBNAME.3.log
[ -d $DEST/$JOBNAME.1 ]     && mv $DEST/$JOBNAME.1 $DEST/$JOBNAME.2
[ -f $LOGS/$JOBNAME.1.log ] && mv $LOGS/$JOBNAME.1.log $LOGS/$JOBNAME.2.log
[ -d $DEST/$JOBNAME ]       && mv $DEST/$JOBNAME $DEST/$JOBNAME.1
[ -f $LOGS/$JOBNAME.log ]   && mv $LOGS/$JOBNAME.log $LOGS/$JOBNAME.1.log

# BACKUP

rsync \
  --archive \
  --verbose \
  --compress \
  --human-readable \
  --progress \
  --stats \
  --delete \
  --delete-excluded \
  --log-file=$LOGS/$JOBNAME.log \
  --link-dest=$DEST/$JOBNAME.1 \
  $SRC/ $DEST/$JOBNAME

RESULT=$?

mkdir -p $DEST/$JOBNAME
touch $DEST

# NOTIFICATIONS

function notify {
  COLOUR=$1
  MSG=$2
  RESULT=$3
  JSON="{\"attachments\":[{\"fallback\":\"$MSG\",\"pretext\":\"$MSG\",\"color\":\"$COLOUR\",\"fields\":[{\"value\":\"$RESULT\",\"short\":0}]}],\"link_names\":1}"
  #curl --silent --show-error --insecure --data "$JSON" "https://hooks.slack.com/services/$SLACKID"
}

if [ $RESULT -ne 0 ]; then
  LOG_MSG=$( tail -4 $LOGS/$JOBNAME.log | cut -d' ' -f4- )

  notify danger "Backup '$JOBNAME' failed on '$HOSTNAME'." "$LOG_MSG"
  exit 1
fi

LOG=$( tail -14 $LOGS/$JOBNAME.log | cut -d' ' -f4- )
LOG_MSG=$( sed -n "/\(Number of files\)/p" <<< "$LOG" )
LOG_MSG=$LOG_MSG$( echo -en "\n" && sed -n "/\(Total file size\)/p" <<< "$LOG" )
LOG_MSG=$LOG_MSG$( echo -en "\n" && sed -n "/\(Total transferred file size\)/p" <<< "$LOG" )

notify good "Backup '$JOBNAME' completed successfully on '$HOSTNAME'." "$LOG_MSG"
