#!/bin/bash

NOTEFILE=$1
DATELINK="$2"
NOTEHEADER="`echo "$(<"$NOTEFILE")" | head -7`"
TMPFILE=`tempfile -m 777`

[ -n "$DATELINK" ] || DATELINK=$( zenity --title "Link to Date" --entry --text="Insert a date in format: 2010-12-31")

CURRDATE="`date --date "$DATELINK" +%F`T00:00:00.000001"
NOTEHEADER="`echo "$NOTEHEADER" | sed "s|^\(Creation-Date: \).*$|\1${CURRDATE}|g"`"

PRETTYDATE="`date --date $DATELINK "+%B %d, %Y"`"

echo -e "`echo "$NOTEHEADER" | head -5`\n\nOn $PRETTYDATE\n" > $TMPFILE
echo -e "`echo "$(<$NOTEFILE)" | tail -n +8`" >> $TMPFILE

cat $TMPFILE > $NOTEFILE
rm $TMPFILE;
exit 0
