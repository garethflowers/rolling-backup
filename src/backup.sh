#!/bin/bash
set -e

# OPTS

SRC=$1
DEST=$2
JOBNAME=$3
LOGS=$DEST/logs
HOSTNAME=$( hostname )

[ -z "$SRC" ] && echo "No source set!"
[ -z "$DEST" ] && echo "No destination set!"

[ -z "$JOBNAME" ] && JOBNAME=backup
[ -f "$DEST" ] && rm -f "$DEST"
[ ! -d "$DEST" ] && mkdir -p "$DEST"
[ ! -d "$LOGS" ] && mkdir -p "$LOGS"

# ROTATE

[ -d "$DEST/$JOBNAME.3" ] && rm -fr "$DEST/$JOBNAME.3"
[ -f "$LOGS/$JOBNAME.3.log" ] && rm -f "$LOGS/$JOBNAME.3.log"
[ -d "$DEST/$JOBNAME.2" ] && mv "$DEST/$JOBNAME.2" "$DEST/$JOBNAME.3"
[ -f "$LOGS/$JOBNAME.2.log" ] && mv "$LOGS/$JOBNAME.2.log" "$LOGS/$JOBNAME.3.log"
[ -d "$DEST/$JOBNAME.1" ] && mv "$DEST/$JOBNAME.1" "$DEST/$JOBNAME.2"
[ -f "$LOGS/$JOBNAME.1.log" ] && mv "$LOGS/$JOBNAME.1.log" "$LOGS/$JOBNAME.2.log"
[ -d "$DEST/$JOBNAME" ] && mv "$DEST/$JOBNAME" "$DEST/$JOBNAME.1"
[ -f "$LOGS/$JOBNAME.log" ] && mv "$LOGS/$JOBNAME.log" "$LOGS/$JOBNAME.1.log"

# BACKUP

rsync \
	--acls \
	--archive \
	--compress \
	--crtimes \
	--delete \
	--delete-excluded \
	--exclude="._*" \
	--exclude=".DS_Store" \
	--fileflags \
	--force-change \
	--hard-links \
	--human-readable \
	--inplace \
	--itemize-changes \
	--link-dest="$DEST/$JOBNAME.1" \
	--log-file="$LOGS/$JOBNAME.log" \
	--one-file-system \
	--partial \
	--progress \
	--stats \
	--verbose \
	--xattrs \
	"$SRC/" "$DEST/$JOBNAME"

RESULT=$?

mkdir -p "$DEST/$JOBNAME"
touch "$DEST"

# NOTIFICATIONS

if [ $RESULT -ne 0 ]; then
	LOG_MSG=$( tail -4 "$LOGS/$JOBNAME.log" | cut -d' ' -f4- )
	logger -is -tag $0 "Backup '$JOBNAME' failed on '$HOSTNAME'. $LOG_MSG"
else
	LOG=$( tail -14 "$LOGS/$JOBNAME.log" | cut -d' ' -f4- )
	LOG_MSG=$( sed -n "/\(Number of files\)/p" <<< "$LOG" )
	LOG_MSG=$LOG_MSG$( echo -en "\n" && sed -n "/\(Total file size\)/p" <<< "$LOG" )
	LOG_MSG=$LOG_MSG$( echo -en "\n" && sed -n "/\(Total transferred file size\)/p" <<< "$LOG" )
	logger -is -tag $0 "Backup '$JOBNAME' completed successfully on '$HOSTNAME'. $LOG_MSG"
fi
